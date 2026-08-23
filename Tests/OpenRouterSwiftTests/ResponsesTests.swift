import XCTest
@testable import OpenRouterSwift

final class ResponsesTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.service(apiKey: "sk-or-test", httpClient: mock)
  }

  private let responseFixture = """
    {
      "object": "response",
      "id": "resp_1",
      "created_at": 1756000000,
      "status": "completed",
      "model": "openai/gpt-4o",
      "output": [
        {"type": "reasoning", "id": "rs_1", "summary": [{"type": "summary_text", "text": "thought"}], "encrypted_content": "enc"},
        {"type": "message", "id": "m_1", "role": "assistant", "status": "completed",
         "content": [{"type": "output_text", "text": "The answer", "annotations": []}]},
        {"type": "function_call", "call_id": "call_1", "name": "get_weather", "arguments": "{\\"city\\":\\"SF\\"}"}
      ],
      "error": null,
      "usage": {
        "input_tokens": 12,
        "input_tokens_details": {"cached_tokens": 4},
        "output_tokens": 20,
        "output_tokens_details": {"reasoning_tokens": 6},
        "total_tokens": 32,
        "cost": 0.0003
      }
    }
    """

  func testResponseRequestAndDecoding() async throws {
    mock.enqueueJSON(responseFixture)

    let result = try await service.response(
      ResponsesRequest(
        model: "openai/gpt-4o",
        input: .items([
          .system("Be helpful"),
          .user("What is the answer?"),
        ]),
        maxOutputTokens: 500,
        reasoning: ResponsesReasoning(effort: .high, summary: .auto),
        text: ResponsesTextConfig(verbosity: "low"),
        tools: [.function(name: "get_weather", parameters: ["type": "object"])],
        provider: ProviderPreferences(sort: .latency)))

    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(request.url.absoluteString, "https://openrouter.ai/api/v1/responses")
    let body = try bodyJSON(request)
    XCTAssertEqual(body["model"] as? String, "openai/gpt-4o")
    XCTAssertEqual(body["max_output_tokens"] as? Int, 500)
    XCTAssertNil(body["store"])
    XCTAssertNil(body["previous_response_id"])
    let input = try XCTUnwrap(body["input"] as? [[String: Any]])
    XCTAssertEqual(input[0]["type"] as? String, "message")
    XCTAssertEqual(input[0]["role"] as? String, "system")
    XCTAssertEqual(input[1]["content"] as? String, "What is the answer?")
    let tools = try XCTUnwrap(body["tools"] as? [[String: Any]])
    XCTAssertEqual(tools[0]["type"] as? String, "function")
    XCTAssertEqual(tools[0]["name"] as? String, "get_weather")

    XCTAssertEqual(result.status, "completed")
    XCTAssertEqual(result.text, "The answer")
    XCTAssertEqual(result.usage?.cost, 0.0003)
    XCTAssertEqual(result.usage?.outputTokensDetails?.reasoningTokens, 6)

    guard case .reasoning(_, let summary, _, let encrypted) = result.output[0] else {
      return XCTFail("Expected reasoning item")
    }
    XCTAssertEqual(summary, ["thought"])
    XCTAssertEqual(encrypted, "enc")

    guard case .functionCall(let callId, let name, let arguments, _, _) = result.output[2] else {
      return XCTFail("Expected function_call item")
    }
    XCTAssertEqual(callId, "call_1")
    XCTAssertEqual(name, "get_weather")
    XCTAssertTrue(arguments.contains("SF"))
  }

  func testResponseStreamEvents() async throws {
    mock.enqueue(.lines([
      #"data: {"type":"response.created","sequence_number":0,"response":{"object":"response","id":"resp_1","status":"in_progress","output":[]}}"#,
      #"data: {"type":"response.output_text.delta","sequence_number":1,"item_id":"m_1","output_index":0,"content_index":0,"delta":"Hel","logprobs":[]}"#,
      #"data: {"type":"response.output_text.delta","sequence_number":2,"item_id":"m_1","output_index":0,"content_index":0,"delta":"lo","logprobs":[]}"#,
      #"data: {"type":"response.web_search_call.searching","sequence_number":3,"item_id":"ws_1","output_index":1}"#,
      """
      data: {"type":"response.completed","sequence_number":4,"response":{"object":"response","id":"resp_1","status":"completed","output":[{"type":"message","id":"m_1","role":"assistant","content":[{"type":"output_text","text":"Hello"}]}],"usage":{"input_tokens":1,"output_tokens":2,"total_tokens":3,"cost":0.0001}}}
      """,
      "data: [DONE]",
    ], statusCode: 200))

    let stream = try await service.responseStream(
      ResponsesRequest(model: "openai/gpt-4o", input: .text("hi")))

    var text = ""
    var completed: ResponsesResponse?
    var otherTypes = [String]()
    for try await event in stream {
      switch event {
      case .outputTextDelta(_, _, let delta):
        text += delta
      case .completed(let response):
        completed = response
      case .other(let type, _):
        otherTypes.append(type)
      default:
        break
      }
    }

    XCTAssertEqual(text, "Hello")
    XCTAssertEqual(completed?.text, "Hello")
    XCTAssertEqual(completed?.usage?.cost, 0.0001)
    XCTAssertEqual(otherTypes, ["response.web_search_call.searching"])
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["stream"] as? Bool, true)
  }
}
