import Foundation
import SwiftOpenAI

// MARK: - AnyEncodable

struct AnyEncodable: Encodable {
  let value: any Encodable

  func encode(to encoder: Encoder) throws {
    try value.encode(to: encoder)
  }
}

// MARK: - OpenRouterTransport

/// Thin request/response layer on top of SwiftOpenAI's cross-platform `HTTPClient`,
/// with OpenRouter-specific error mapping and SSE handling.
struct OpenRouterTransport {
  let httpClient: HTTPClient
  let baseURL: String
  let defaultHeaders: [String: String]
  let encoder: JSONEncoder
  let decoder: JSONDecoder
  let debugEnabled: Bool

  init(
    httpClient: HTTPClient,
    baseURL: String,
    defaultHeaders: [String: String],
    debugEnabled: Bool)
  {
    self.httpClient = httpClient
    self.baseURL = baseURL
    self.defaultHeaders = defaultHeaders
    encoder = JSONEncoder()
    decoder = JSONDecoder()
    self.debugEnabled = debugEnabled
  }

  // MARK: Request building

  func request(
    _ api: OpenRouterAPI,
    method methodOverride: HTTPMethod? = nil,
    queryItems: [URLQueryItem] = [],
    body: (any Encodable)? = nil)
    throws -> HTTPRequest
  {
    let method = methodOverride ?? api.method
    guard var components = URLComponents(string: baseURL) else {
      throw OpenRouterError.invalidResponse(description: "Invalid base URL: \(baseURL)")
    }
    components.path = api.path
    if !queryItems.isEmpty {
      components.queryItems = queryItems
    }
    guard let url = components.url else {
      throw OpenRouterError.invalidResponse(description: "Could not build URL for \(api.path)")
    }
    var headers = defaultHeaders
    var data: Data? = nil
    if let body {
      headers["Content-Type"] = "application/json"
      data = try encoder.encode(AnyEncodable(value: body))
    }
    if debugEnabled {
      let bodyText = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<none>"
      print("[OpenRouterSwift] \(method.rawValue) \(url.absoluteString)\n\(bodyText)")
    }
    return HTTPRequest(url: url, method: method, headers: headers, body: data)
  }

  /// Builds a request with a pre-encoded body (multipart uploads, raw payloads).
  func rawRequest(
    _ api: OpenRouterAPI,
    body: Data,
    contentType: String)
    throws -> HTTPRequest
  {
    var httpRequest = try request(api)
    httpRequest.body = body
    httpRequest.headers["Content-Type"] = contentType
    return httpRequest
  }

  /// Executes a pre-built request and decodes the JSON response.
  func fetch<T: Decodable>(request httpRequest: HTTPRequest) async throws -> T {
    let data = try await fetchData(request: httpRequest)
    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw OpenRouterError.decodingFailure(description: "\(error)", raw: data)
    }
  }

  /// Executes a pre-built request and returns the raw body.
  func fetchData(request httpRequest: HTTPRequest) async throws -> Data {
    let (data, response): (Data, HTTPResponse)
    do {
      (data, response) = try await httpClient.data(for: httpRequest)
    } catch {
      throw OpenRouterError.transport(error)
    }
    if debugEnabled {
      let text = String(data: data, encoding: .utf8) ?? "<binary \(data.count) bytes>"
      print("[OpenRouterSwift] ← \(response.statusCode)\n\(text)")
    }
    guard (200..<300).contains(response.statusCode) else {
      throw mapError(statusCode: response.statusCode, headers: response.headers, data: data)
    }
    return data
  }

  // MARK: Fetching

  func fetch<T: Decodable>(
    _ api: OpenRouterAPI,
    method: HTTPMethod? = nil,
    queryItems: [URLQueryItem] = [],
    body: (any Encodable)? = nil)
    async throws -> T
  {
    let data = try await fetchData(api, method: method, queryItems: queryItems, body: body)
    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw OpenRouterError.decodingFailure(description: "\(error)", raw: data)
    }
  }

  func fetchData(
    _ api: OpenRouterAPI,
    method: HTTPMethod? = nil,
    queryItems: [URLQueryItem] = [],
    body: (any Encodable)? = nil)
    async throws -> Data
  {
    try await fetchData(request: try request(api, method: method, queryItems: queryItems, body: body))
  }

  // MARK: Streaming

  func fetchStream<T: Decodable & Sendable>(
    _ api: OpenRouterAPI,
    body: any Encodable)
    async throws -> AsyncThrowingStream<T, Error>
  {
    let httpRequest = try request(api, body: body)
    let (byteStream, response): (HTTPByteStream, HTTPResponse)
    do {
      (byteStream, response) = try await httpClient.bytes(for: httpRequest)
    } catch {
      throw OpenRouterError.transport(error)
    }

    guard (200..<300).contains(response.statusCode) else {
      // Drain the stream so the error body can be decoded.
      var errorData = Data()
      switch byteStream {
      case .lines(let lines):
        for try await line in lines {
          errorData.append(Data(line.utf8))
        }
      case .bytes(let bytes):
        for try await byte in bytes {
          errorData.append(byte)
        }
      }
      throw mapError(statusCode: response.statusCode, headers: response.headers, data: errorData)
    }

    let decoder = decoder
    let debugEnabled = debugEnabled
    return AsyncThrowingStream { continuation in
      let task = Task {
        do {
          let lines = try Self.lineStream(from: byteStream)
          for try await line in lines {
            try Task.checkCancellation()
            switch SSEParser.parse(line: line) {
            case .comment, .ignore, .event:
              continue

            case .done:
              continuation.finish()
              return

            case .data(let payload):
              if debugEnabled {
                print("[OpenRouterSwift] ⇊ \(payload)")
              }
              let data = Data(payload.utf8)
              // Mid-stream errors arrive as data events under HTTP 200.
              if let envelope = try? decoder.decode(OpenRouterErrorEnvelope.self, from: data) {
                throw OpenRouterError.streamError(
                  code: envelope.error.code,
                  message: envelope.error.message,
                  metadata: envelope.error.metadata)
              }
              do {
                let chunk = try decoder.decode(T.self, from: data)
                continuation.yield(chunk)
              } catch {
                throw OpenRouterError.decodingFailure(description: "\(error)", raw: data)
              }
            }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  /// Normalizes either byte-stream flavor into a stream of lines.
  private static func lineStream(from byteStream: HTTPByteStream) throws -> AsyncThrowingStream<String, Error> {
    switch byteStream {
    case .lines(let lines):
      return lines

    case .bytes(let bytes):
      return AsyncThrowingStream { continuation in
        let task = Task {
          var buffer = [UInt8]()
          do {
            for try await byte in bytes {
              if byte == UInt8(ascii: "\n") {
                continuation.yield(String(decoding: buffer, as: UTF8.self))
                buffer.removeAll(keepingCapacity: true)
              } else {
                buffer.append(byte)
              }
            }
            if !buffer.isEmpty {
              continuation.yield(String(decoding: buffer, as: UTF8.self))
            }
            continuation.finish()
          } catch {
            continuation.finish(throwing: error)
          }
        }
        continuation.onTermination = { _ in
          task.cancel()
        }
      }
    }
  }

  // MARK: Error mapping

  func mapError(statusCode: Int, headers: [String: String], data: Data) -> OpenRouterError {
    let body = try? decoder.decode(OpenRouterErrorEnvelope.self, from: data)
    let message = body?.error.message
      ?? String(data: data, encoding: .utf8)
      ?? "Unknown error"
    let metadata = body?.error.metadata

    switch statusCode {
    case 402:
      return .insufficientCredits(message: message)
    case 403:
      return .guardrailViolation(message: message, metadata: metadata)
    case 429:
      let retryAfter = headers
        .first { $0.key.lowercased() == "retry-after" }
        .flatMap { TimeInterval($0.value) }
      return .rateLimited(message: message, retryAfter: retryAfter)
    case 524:
      return .providerTimeout(message: message)
    case 529:
      return .serviceOverloaded(message: message)
    default:
      return .api(statusCode: statusCode, message: message, metadata: metadata)
    }
  }
}
