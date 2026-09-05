import XCTest
@testable import OpenRouterSwift

final class ChatCompletionRequestEncodingTests: XCTestCase {
  private func encodeToDictionary(_ request: ChatCompletionRequest) throws -> [String: Any] {
    let data = try JSONEncoder().encode(request)
    return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  func testSnakeCaseKeysAndOpenRouterParams() throws {
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o",
      models: ["anthropic/claude-sonnet-4.5", "meta-llama/llama-3-70b"],
      messages: [.user("hi")],
      provider: ProviderPreferences(
        allowFallbacks: false,
        order: ["openai", "azure"],
        sort: .throughput,
        zdr: true,
        quantizations: ["fp16"]),
      reasoning: Reasoning(effort: .high, summary: .concise),
      sessionId: "session-123",
      topK: 40,
      minP: 0.05,
      topA: 0.2,
      repetitionPenalty: 1.1,
      maxTokens: 512)

    let json = try encodeToDictionary(request)

    XCTAssertEqual(json["model"] as? String, "openai/gpt-4o")
    XCTAssertEqual(json["models"] as? [String], ["anthropic/claude-sonnet-4.5", "meta-llama/llama-3-70b"])
    XCTAssertEqual(json["session_id"] as? String, "session-123")
    XCTAssertEqual(json["top_k"] as? Int, 40)
    XCTAssertEqual(json["min_p"] as? Double, 0.05)
    XCTAssertEqual(json["top_a"] as? Double, 0.2)
    XCTAssertEqual(json["repetition_penalty"] as? Double, 1.1)
    XCTAssertEqual(json["max_tokens"] as? Int, 512)

    let provider = try XCTUnwrap(json["provider"] as? [String: Any])
    XCTAssertEqual(provider["allow_fallbacks"] as? Bool, false)
    XCTAssertEqual(provider["order"] as? [String], ["openai", "azure"])
    XCTAssertEqual(provider["sort"] as? String, "throughput")
    XCTAssertEqual(provider["zdr"] as? Bool, true)
    XCTAssertEqual(provider["quantizations"] as? [String], ["fp16"])

    let reasoning = try XCTUnwrap(json["reasoning"] as? [String: Any])
    XCTAssertEqual(reasoning["effort"] as? String, "high")
    XCTAssertEqual(reasoning["summary"] as? String, "concise")
  }

  func testPluginEncoding() throws {
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o",
      messages: [.user("search this")],
      plugins: [
        .web(Plugin.WebConfig(engine: "exa", maxResults: 3)),
        .moderation,
        .contextCompression(Plugin.ContextCompressionConfig(engine: "middle-out", enabled: true)),
        .custom(id: "future-plugin", config: ["knob": .int(7)]),
      ])

    let json = try encodeToDictionary(request)
    let plugins = try XCTUnwrap(json["plugins"] as? [[String: Any]])
    XCTAssertEqual(plugins.count, 4)

    XCTAssertEqual(plugins[0]["id"] as? String, "web")
    XCTAssertEqual(plugins[0]["engine"] as? String, "exa")
    XCTAssertEqual(plugins[0]["max_results"] as? Int, 3)

    XCTAssertEqual(plugins[1]["id"] as? String, "moderation")
    XCTAssertEqual(plugins[1].count, 1)

    XCTAssertEqual(plugins[2]["id"] as? String, "context-compression")
    XCTAssertEqual(plugins[2]["engine"] as? String, "middle-out")
    XCTAssertEqual(plugins[2]["enabled"] as? Bool, true)

    XCTAssertEqual(plugins[3]["id"] as? String, "future-plugin")
    XCTAssertEqual(plugins[3]["knob"] as? Int, 7)
  }

  func testResponseFormatGrammarAndJSONSchema() throws {
    let grammarRequest = ChatCompletionRequest(
      model: "m",
      messages: [.user("x")],
      responseFormat: .grammar("root ::= \"yes\" | \"no\""))
    let grammarJSON = try encodeToDictionary(grammarRequest)
    let grammarFormat = try XCTUnwrap(grammarJSON["response_format"] as? [String: Any])
    XCTAssertEqual(grammarFormat["type"] as? String, "grammar")
    XCTAssertEqual(grammarFormat["grammar"] as? String, "root ::= \"yes\" | \"no\"")

    let schemaRequest = ChatCompletionRequest(
      model: "m",
      messages: [.user("x")],
      responseFormat: .jsonSchema(
        name: "weather",
        schema: ["type": "object", "properties": ["temp": ["type": "number"]]],
        strict: true))
    let schemaJSON = try encodeToDictionary(schemaRequest)
    let schemaFormat = try XCTUnwrap(schemaJSON["response_format"] as? [String: Any])
    XCTAssertEqual(schemaFormat["type"] as? String, "json_schema")
    let payload = try XCTUnwrap(schemaFormat["json_schema"] as? [String: Any])
    XCTAssertEqual(payload["name"] as? String, "weather")
    XCTAssertEqual(payload["strict"] as? Bool, true)
  }

  func testExtraBodyMergesAtTopLevelWithoutOverridingTypedFields() throws {
    let request = ChatCompletionRequest(
      model: "typed-model",
      messages: [.user("x")],
      extraBody: [
        "brand_new_param": .string("value"),
        "nested": .object(["a": .int(1)]),
        "model": .string("should-not-override"),
      ])

    let json = try encodeToDictionary(request)
    XCTAssertEqual(json["brand_new_param"] as? String, "value")
    XCTAssertEqual((json["nested"] as? [String: Any])?["a"] as? Int, 1)
    XCTAssertEqual(json["model"] as? String, "typed-model")
  }

  func testMultimodalContentPartsWithCacheControl() throws {
    let request = ChatCompletionRequest(
      model: "m",
      messages: [
        Message(role: .user, content: .parts([
          .text("What is in this image?", cacheControl: .ephemeral),
          .imageURL(url: "https://example.com/cat.png", detail: "high"),
        ])),
      ])

    let json = try encodeToDictionary(request)
    let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
    let parts = try XCTUnwrap(messages[0]["content"] as? [[String: Any]])
    XCTAssertEqual(parts[0]["type"] as? String, "text")
    XCTAssertEqual((parts[0]["cache_control"] as? [String: Any])?["type"] as? String, "ephemeral")
    XCTAssertEqual(parts[1]["type"] as? String, "image_url")
    XCTAssertEqual((parts[1]["image_url"] as? [String: Any])?["url"] as? String, "https://example.com/cat.png")
  }

  func testToolsAndToolChoice() throws {
    let request = ChatCompletionRequest(
      model: "m",
      messages: [.user("weather?")],
      tools: [
        .function(
          name: "get_weather",
          description: "Get weather",
          parameters: ["type": "object", "properties": ["city": ["type": "string"]]]),
      ],
      toolChoice: .function(name: "get_weather"))

    let json = try encodeToDictionary(request)
    let tools = try XCTUnwrap(json["tools"] as? [[String: Any]])
    XCTAssertEqual(tools[0]["type"] as? String, "function")
    XCTAssertEqual((tools[0]["function"] as? [String: Any])?["name"] as? String, "get_weather")

    let choice = try XCTUnwrap(json["tool_choice"] as? [String: Any])
    XCTAssertEqual(choice["type"] as? String, "function")
    XCTAssertEqual((choice["function"] as? [String: Any])?["name"] as? String, "get_weather")
  }

  func testAssistantReasoningDetailsReplayVerbatimAndAreOmittedWhenNil() throws {
    let block: JSONValue = .object([
      "type": .string("reasoning.text"),
      "format": .string("anthropic-claude-v1"),
      "text": .string("Need the weather first."),
      "signature": .string("sig-abc"),
    ])
    let request = ChatCompletionRequest(
      model: "m",
      messages: [
        .user("weather?"),
        Message(
          role: .assistant,
          toolCalls: [ToolCall(id: "call_1", function: .init(name: "get_weather", arguments: "{}"))],
          reasoningDetails: [block]),
        .tool("sunny", toolCallId: "call_1"),
      ])

    let json = try encodeToDictionary(request)
    let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
    XCTAssertNil(messages[0]["reasoning_details"])
    let details = try XCTUnwrap(messages[1]["reasoning_details"] as? [[String: Any]])
    XCTAssertEqual(details.count, 1)
    XCTAssertEqual(details[0]["type"] as? String, "reasoning.text")
    XCTAssertEqual(details[0]["format"] as? String, "anthropic-claude-v1")
    XCTAssertEqual(details[0]["signature"] as? String, "sig-abc")
    XCTAssertNil(messages[2]["reasoning_details"])
  }

  func testReasoningEffortEncodesAsATopLevelStringApartFromTheReasoningObject() throws {
    // OpenAI's chat-completions spelling: a top-level string, no `reasoning` object beside it.
    let openai = try encodeToDictionary(ChatCompletionRequest(
      model: "m", messages: [.user("hi")], reasoningEffort: .medium))
    XCTAssertEqual(openai["reasoning_effort"] as? String, "medium")
    XCTAssertNil(openai["reasoning"])

    // OpenRouter's spelling: the object, and no `reasoning_effort` key.
    let openrouter = try encodeToDictionary(ChatCompletionRequest(
      model: "m", messages: [.user("hi")], reasoning: Reasoning(effort: .high)))
    XCTAssertEqual((openrouter["reasoning"] as? [String: Any])?["effort"] as? String, "high")
    XCTAssertNil(openrouter["reasoning_effort"])

    // Neither set: neither key.
    let plain = try encodeToDictionary(ChatCompletionRequest(model: "m", messages: [.user("hi")]))
    XCTAssertNil(plain["reasoning"])
    XCTAssertNil(plain["reasoning_effort"])
  }
}
