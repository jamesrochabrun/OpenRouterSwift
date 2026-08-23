import XCTest
import SwiftOpenAI
@testable import OpenRouterSwift

final class ServiceTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.service(
      apiKey: "sk-or-test",
      configuration: OpenRouterConfiguration(
        appReferer: "https://example.com",
        appTitle: "TestApp",
        metadataEnabled: true),
      httpClient: mock)
  }

  private let chatFixture = """
    {
      "id": "gen-abc123",
      "provider": "OpenAI",
      "model": "openai/gpt-4o",
      "object": "chat.completion",
      "created": 1756000000,
      "choices": [
        {
          "index": 0,
          "message": {
            "role": "assistant",
            "content": "Hello!",
            "reasoning": "The user greeted me.",
            "reasoning_details": [{"type": "reasoning.text", "text": "The user greeted me."}]
          },
          "finish_reason": "stop",
          "native_finish_reason": "stop"
        }
      ],
      "usage": {
        "prompt_tokens": 10,
        "completion_tokens": 4,
        "total_tokens": 14,
        "cost": 0.00012,
        "is_byok": false,
        "cost_details": {"upstream_inference_cost": null},
        "prompt_tokens_details": {"cached_tokens": 8},
        "completion_tokens_details": {"reasoning_tokens": 2}
      }
    }
    """

  func testChatCompletionRequestShapeAndDecoding() async throws {
    mock.enqueueJSON(chatFixture)

    let response = try await service.chatCompletion(
      ChatCompletionRequest(model: "openai/gpt-4o", messages: [.user("hi")]))

    // Request assertions
    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(request.url.absoluteString, "https://openrouter.ai/api/v1/chat/completions")
    XCTAssertEqual(request.method.rawValue, "POST")
    XCTAssertEqual(request.headers["Authorization"], "Bearer sk-or-test")
    XCTAssertEqual(request.headers["HTTP-Referer"], "https://example.com")
    XCTAssertEqual(request.headers["X-OpenRouter-Title"], "TestApp")
    XCTAssertEqual(request.headers["X-Title"], "TestApp")
    XCTAssertEqual(request.headers["X-OpenRouter-Metadata"], "enabled")
    XCTAssertEqual(request.headers["Content-Type"], "application/json")
    let body = try bodyJSON(request)
    XCTAssertEqual(body["model"] as? String, "openai/gpt-4o")
    XCTAssertNil(body["stream"])

    // Response assertions
    XCTAssertEqual(response.id, "gen-abc123")
    XCTAssertEqual(response.provider, "OpenAI")
    XCTAssertEqual(response.choices.first?.message.content, "Hello!")
    XCTAssertEqual(response.choices.first?.message.reasoning, "The user greeted me.")
    XCTAssertEqual(response.usage?.cost, 0.00012)
    XCTAssertEqual(response.usage?.promptTokensDetails?.cachedTokens, 8)
    XCTAssertEqual(response.usage?.completionTokensDetails?.reasoningTokens, 2)
  }

  func testInsufficientCreditsMapsTo402Error() async throws {
    mock.enqueueJSON(
      #"{"error": {"code": 402, "message": "Insufficient credits", "metadata": {"required": 0.01}}}"#,
      statusCode: 402)

    do {
      _ = try await service.chatCompletion(ChatCompletionRequest(model: "m", messages: [.user("x")]))
      XCTFail("Expected error")
    } catch let error as OpenRouterError {
      guard case .insufficientCredits(let message) = error else {
        return XCTFail("Wrong error: \(error)")
      }
      XCTAssertEqual(message, "Insufficient credits")
    }
  }

  func testRateLimitedParsesRetryAfterHeader() async throws {
    mock.enqueueJSON(
      #"{"error": {"code": 429, "message": "Rate limited"}}"#,
      statusCode: 429,
      headers: ["Retry-After": "30"])

    do {
      _ = try await service.chatCompletion(ChatCompletionRequest(model: "m", messages: [.user("x")]))
      XCTFail("Expected error")
    } catch let error as OpenRouterError {
      guard case .rateLimited(_, let retryAfter) = error else {
        return XCTFail("Wrong error: \(error)")
      }
      XCTAssertEqual(retryAfter, 30)
    }
  }

  func testModelsFilterBuildsQueryItems() async throws {
    mock.enqueueJSON(#"{"data": [{"id": "openai/gpt-4o", "name": "GPT-4o", "context_length": 128000}]}"#)

    let models = try await service.models(
      filter: ModelsFilter(
        supportedParameters: ["tools", "response_format"],
        q: "gpt",
        context: 32000,
        zdr: true,
        limit: 10,
        sort: .contextHighToLow))

    let url = try XCTUnwrap(mock.lastRequest?.url)
    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    XCTAssertEqual(components.path, "/api/v1/models")
    let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
    XCTAssertEqual(query["supported_parameters"], "tools,response_format")
    XCTAssertEqual(query["q"], "gpt")
    XCTAssertEqual(query["context"], "32000")
    XCTAssertEqual(query["zdr"], "true")
    XCTAssertEqual(query["limit"], "10")
    XCTAssertEqual(query["sort"], "context-high-to-low")

    XCTAssertEqual(models.count, 1)
    XCTAssertEqual(models.first?.id, "openai/gpt-4o")
    XCTAssertEqual(models.first?.contextLength, 128000)
  }

  func testKeyInfoAndCredits() async throws {
    mock.enqueueJSON(
      #"{"data": {"label": "sk-or-v1-abc", "limit": 100, "usage": 42.5, "is_free_tier": false, "is_management_key": false, "limit_remaining": 57.5}}"#)
    let key = try await service.keyInfo()
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/key")
    XCTAssertEqual(key.label, "sk-or-v1-abc")
    XCTAssertEqual(key.limitRemaining, 57.5)
    XCTAssertEqual(key.isFreeTier, false)

    mock.enqueueJSON(#"{"data": {"total_credits": 50, "total_usage": 12.5}}"#)
    let credits = try await service.credits()
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/credits")
    XCTAssertEqual(credits.remaining, 37.5)
  }

  func testGenerationStats() async throws {
    mock.enqueueJSON("""
      {"data": {
        "id": "gen-abc123",
        "model": "openai/gpt-4o",
        "provider_name": "OpenAI",
        "total_cost": 0.00042,
        "cache_discount": 0.0001,
        "native_tokens_prompt": 12,
        "native_tokens_completion": 30,
        "native_tokens_reasoning": 8,
        "tokens_prompt": 11,
        "tokens_completion": 29,
        "latency": 320,
        "generation_time": 900,
        "finish_reason": "stop",
        "streamed": true
      }}
      """)

    let generation = try await service.generation(id: "gen-abc123")
    let url = try XCTUnwrap(mock.lastRequest?.url)
    XCTAssertEqual(url.absoluteString, "https://openrouter.ai/api/v1/generation?id=gen-abc123")
    XCTAssertEqual(generation.totalCost, 0.00042)
    XCTAssertEqual(generation.nativeTokensReasoning, 8)
    XCTAssertEqual(generation.streamed, true)
  }

  func testModelEndpointsPath() async throws {
    mock.enqueueJSON("""
      {"data": {
        "id": "openai/gpt-4o",
        "name": "GPT-4o",
        "endpoints": [
          {"name": "OpenAI | gpt-4o", "provider_name": "OpenAI", "context_length": 128000,
           "quantization": null, "uptime_last_30m": 99.9, "supports_implicit_caching": true}
        ]
      }}
      """)

    let list = try await service.modelEndpoints(author: "openai", slug: "gpt-4o")
    XCTAssertEqual(
      mock.lastRequest?.url.absoluteString,
      "https://openrouter.ai/api/v1/models/openai/gpt-4o/endpoints")
    XCTAssertEqual(list.endpoints.first?.providerName, "OpenAI")
    XCTAssertEqual(list.endpoints.first?.uptimeLast30m, 99.9)
  }
}
