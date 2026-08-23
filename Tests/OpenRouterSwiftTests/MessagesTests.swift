import XCTest
@testable import OpenRouterSwift

final class MessagesTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.service(apiKey: "sk-or-test", httpClient: mock)
  }

  func testRequestEncodingWithThinkingToolsAndFallbacks() async throws {
    mock.enqueueJSON("""
      {"id": "msg_1", "type": "message", "model": "anthropic/claude-sonnet-4.5", "role": "assistant",
       "content": [{"type": "text", "text": "Hi"}],
       "stop_reason": "end_turn", "stop_sequence": null,
       "usage": {"input_tokens": 10, "output_tokens": 2, "cost": 0.0002, "is_byok": false},
       "provider": "Anthropic"}
      """)

    let response = try await service.message(
      MessagesRequest(
        model: "anthropic/claude-sonnet-4.5",
        messages: [.user("Hello")],
        maxTokens: 1024,
        system: "Be brief.",
        thinking: .enabled(budgetTokens: 2048),
        tools: [.custom(name: "lookup", inputSchema: ["type": "object"])],
        toolChoice: .auto(),
        models: ["openai/gpt-4o"],
        provider: ProviderPreferences(sort: .price)))

    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(request.url.absoluteString, "https://openrouter.ai/api/v1/messages")
    let body = try bodyJSON(request)
    XCTAssertEqual(body["model"] as? String, "anthropic/claude-sonnet-4.5")
    XCTAssertEqual(body["max_tokens"] as? Int, 1024)
    XCTAssertEqual(body["system"] as? String, "Be brief.")
    XCTAssertEqual(body["models"] as? [String], ["openai/gpt-4o"])
    XCTAssertNil(body["stream"])

    let thinking = try XCTUnwrap(body["thinking"] as? [String: Any])
    XCTAssertEqual(thinking["type"] as? String, "enabled")
    XCTAssertEqual(thinking["budget_tokens"] as? Int, 2048)

    let tools = try XCTUnwrap(body["tools"] as? [[String: Any]])
    XCTAssertEqual(tools[0]["name"] as? String, "lookup")
    XCTAssertNotNil(tools[0]["input_schema"])

    XCTAssertEqual((body["tool_choice"] as? [String: Any])?["type"] as? String, "auto")
    XCTAssertEqual((body["provider"] as? [String: Any])?["sort"] as? String, "price")

    XCTAssertEqual(response.text, "Hi")
    XCTAssertEqual(response.stopReason, "end_turn")
    XCTAssertEqual(response.usage?.cost, 0.0002)
    XCTAssertEqual(response.provider, "Anthropic")
  }

  func testResponseContentBlockDecoding() async throws {
    mock.enqueueJSON("""
      {"id": "msg_2", "type": "message", "model": "m", "role": "assistant",
       "content": [
         {"type": "thinking", "thinking": "Let me think...", "signature": "sig"},
         {"type": "text", "text": "Answer"},
         {"type": "tool_use", "id": "tu_1", "name": "lookup", "input": {"q": "swift"}},
         {"type": "web_search_tool_result", "tool_use_id": "tu_2", "content": []}
       ],
       "stop_reason": "tool_use", "stop_sequence": null,
       "usage": {"input_tokens": 1, "output_tokens": 1}}
      """)

    let response = try await service.message(MessagesRequest(model: "m", messages: [.user("x")]))
    XCTAssertEqual(response.content.count, 4)

    guard case .thinking(let thinking, let signature) = response.content[0] else {
      return XCTFail("Expected thinking block")
    }
    XCTAssertEqual(thinking, "Let me think...")
    XCTAssertEqual(signature, "sig")

    XCTAssertEqual(response.content[1].textValue, "Answer")

    guard case .toolUse(let id, let name, let input) = response.content[2] else {
      return XCTFail("Expected tool_use block")
    }
    XCTAssertEqual(id, "tu_1")
    XCTAssertEqual(name, "lookup")
    XCTAssertEqual(input["q"]?.stringValue, "swift")

    guard case .other(let type, _) = response.content[3] else {
      return XCTFail("Expected other block")
    }
    XCTAssertEqual(type, "web_search_tool_result")
  }

  func testStreamEvents() async throws {
    mock.enqueue(.lines([
      ": OPENROUTER PROCESSING",
      "event: message_start",
      #"data: {"type":"message_start","message":{"id":"msg_1","model":"m","role":"assistant","content":[]}}"#,
      "event: content_block_start",
      #"data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#,
      "event: content_block_delta",
      #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hel"}}"#,
      #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"lo"}}"#,
      #"data: {"type":"content_block_stop","index":0}"#,
      #"data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":2}}"#,
      #"data: {"type":"message_stop"}"#,
      "data: [DONE]",
    ], statusCode: 200))

    let stream = try await service.messageStream(MessagesRequest(model: "m", messages: [.user("hi")]))

    var text = ""
    var sawStop = false
    for try await event in stream {
      switch event {
      case .contentBlockDelta(_, .textDelta(let delta)):
        text += delta
      case .messageStop:
        sawStop = true
      default:
        break
      }
    }

    XCTAssertEqual(text, "Hello")
    XCTAssertTrue(sawStop)
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["stream"] as? Bool, true)
  }
}
