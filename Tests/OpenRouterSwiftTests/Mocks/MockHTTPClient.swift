import Foundation
import SwiftOpenAI
@testable import OpenRouterSwift

/// Scripted HTTPClient: records every request and replays queued responses.
final class MockHTTPClient: HTTPClient, @unchecked Sendable {
  enum ScriptedResponse {
    case data(Data, statusCode: Int, headers: [String: String] = [:])
    case lines([String], statusCode: Int, headers: [String: String] = [:])
  }

  private let lock = NSLock()
  private var queue: [ScriptedResponse] = []
  private(set) var requests: [HTTPRequest] = []

  func enqueue(_ response: ScriptedResponse) {
    lock.lock()
    defer { lock.unlock() }
    queue.append(response)
  }

  func enqueueJSON(_ json: String, statusCode: Int = 200, headers: [String: String] = [:]) {
    enqueue(.data(Data(json.utf8), statusCode: statusCode, headers: headers))
  }

  private func next() -> ScriptedResponse {
    lock.lock()
    defer { lock.unlock() }
    precondition(!queue.isEmpty, "MockHTTPClient: no scripted response left")
    return queue.removeFirst()
  }

  private func record(_ request: HTTPRequest) {
    lock.lock()
    defer { lock.unlock() }
    requests.append(request)
  }

  var lastRequest: HTTPRequest? {
    lock.lock()
    defer { lock.unlock() }
    return requests.last
  }

  // MARK: HTTPClient

  func data(for request: HTTPRequest) async throws -> (Data, HTTPResponse) {
    record(request)
    switch next() {
    case .data(let data, let statusCode, let headers):
      return (data, HTTPResponse(statusCode: statusCode, headers: headers))
    case .lines(let lines, let statusCode, let headers):
      let data = Data(lines.joined(separator: "\n").utf8)
      return (data, HTTPResponse(statusCode: statusCode, headers: headers))
    }
  }

  func bytes(for request: HTTPRequest) async throws -> (HTTPByteStream, HTTPResponse) {
    record(request)
    switch next() {
    case .data(let data, let statusCode, let headers):
      let stream = AsyncThrowingStream<String, Error> { continuation in
        continuation.yield(String(decoding: data, as: UTF8.self))
        continuation.finish()
      }
      return (.lines(stream), HTTPResponse(statusCode: statusCode, headers: headers))

    case .lines(let lines, let statusCode, let headers):
      let stream = AsyncThrowingStream<String, Error> { continuation in
        for line in lines {
          continuation.yield(line)
        }
        continuation.finish()
      }
      return (.lines(stream), HTTPResponse(statusCode: statusCode, headers: headers))
    }
  }
}

// MARK: - Test helpers

func bodyJSON(_ request: HTTPRequest?) throws -> [String: Any] {
  guard let body = request?.body else { return [:] }
  let object = try JSONSerialization.jsonObject(with: body)
  return object as? [String: Any] ?? [:]
}
