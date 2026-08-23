import XCTest
import SwiftOpenAI
@testable import OpenRouterSwift

final class StreamingTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.service(apiKey: "sk-or-test", httpClient: mock)
  }

  private func chunk(_ content: String) -> String {
    #"data: {"id":"gen-1","model":"openai/gpt-4o","choices":[{"index":0,"delta":{"content":"\#(content)"}}]}"#
  }

  func testStreamSkipsCommentsAndYieldsUsageOnFinalChunk() async throws {
    mock.enqueue(.lines([
      ": OPENROUTER PROCESSING",
      chunk("Hel"),
      ": OPENROUTER PROCESSING",
      chunk("lo"),
      #"data: {"id":"gen-1","model":"openai/gpt-4o","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":5,"completion_tokens":2,"total_tokens":7,"cost":0.0001}}"#,
      "data: [DONE]",
    ], statusCode: 200))

    let stream = try await service.chatCompletionStream(
      ChatCompletionRequest(model: "openai/gpt-4o", messages: [.user("hi")]))

    var text = ""
    var finalUsage: OpenRouterSwift.Usage?
    for try await chunk in stream {
      if let delta = chunk.choices?.first?.delta?.content {
        text += delta
      }
      if let usage = chunk.usage {
        finalUsage = usage
      }
    }

    XCTAssertEqual(text, "Hello")
    XCTAssertEqual(finalUsage?.cost, 0.0001)

    // stream: true is forced onto the encoded body
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["stream"] as? Bool, true)
  }

  func testMidStreamErrorUnderHTTP200Throws() async throws {
    mock.enqueue(.lines([
      chunk("partial"),
      #"data: {"error": {"code": 502, "message": "Provider crashed", "metadata": {"provider_name": "SomeProvider"}}}"#,
    ], statusCode: 200))

    let stream = try await service.chatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("x")]))

    var received = [ChatCompletionChunk]()
    do {
      for try await chunk in stream {
        received.append(chunk)
      }
      XCTFail("Expected stream error")
    } catch let error as OpenRouterError {
      guard case .streamError(let code, let message, let metadata) = error else {
        return XCTFail("Wrong error: \(error)")
      }
      XCTAssertEqual(code, 502)
      XCTAssertEqual(message, "Provider crashed")
      XCTAssertEqual(metadata?["provider_name"]?.stringValue, "SomeProvider")
    }
    XCTAssertEqual(received.count, 1)
  }

  func testNon200StreamResponseThrowsMappedError() async throws {
    mock.enqueue(.lines([#"{"error": {"code": 429, "message": "Slow down"}}"#], statusCode: 429))

    do {
      _ = try await service.chatCompletionStream(
        ChatCompletionRequest(model: "m", messages: [.user("x")]))
      XCTFail("Expected error")
    } catch let error as OpenRouterError {
      guard case .rateLimited(let message, _) = error else {
        return XCTFail("Wrong error: \(error)")
      }
      XCTAssertEqual(message, "Slow down")
    }
  }

  func testCancellationTerminatesStream() async throws {
    // An endless stream that only ends when cancelled.
    let endless = AsyncThrowingStream<String, Error> { continuation in
      let task = Task {
        var i = 0
        while !Task.isCancelled {
          continuation.yield(self.chunk("tick\(i)"))
          i += 1
          try await Task.sleep(nanoseconds: 5_000_000)
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }

    final class EndlessClient: HTTPClient, @unchecked Sendable {
      let stream: AsyncThrowingStream<String, Error>
      init(stream: AsyncThrowingStream<String, Error>) { self.stream = stream }
      func data(for _: HTTPRequest) async throws -> (Data, HTTPResponse) {
        (Data(), HTTPResponse(statusCode: 200, headers: [:]))
      }
      func bytes(for _: HTTPRequest) async throws -> (HTTPByteStream, HTTPResponse) {
        (.lines(stream), HTTPResponse(statusCode: 200, headers: [:]))
      }
    }

    let service = OpenRouter.service(apiKey: "k", httpClient: EndlessClient(stream: endless))
    let stream = try await service.chatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("x")]))

    let consumed = expectation(description: "consumed some chunks then stopped")
    let consumer = Task {
      var count = 0
      do {
        for try await _ in stream {
          count += 1
          if count == 3 {
            consumed.fulfill()
          }
        }
      } catch { }
    }

    await fulfillment(of: [consumed], timeout: 5)
    consumer.cancel()
    // If cancellation propagates, the consumer task finishes promptly.
    _ = await consumer.result
  }
}
