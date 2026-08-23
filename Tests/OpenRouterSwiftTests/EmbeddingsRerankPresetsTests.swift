import XCTest
@testable import OpenRouterSwift

final class EmbeddingsRerankPresetsTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.service(apiKey: "sk-or-test", httpClient: mock)
  }

  // MARK: Embeddings

  func testEmbeddings() async throws {
    mock.enqueueJSON("""
      {"object": "list", "model": "openai/text-embedding-3-small",
       "data": [{"object": "embedding", "index": 0, "embedding": [0.1, -0.2, 0.3]}],
       "usage": {"prompt_tokens": 5, "total_tokens": 5, "cost": 0.000001}}
      """)

    let response = try await service.embeddings(
      EmbeddingsRequest(
        model: "openai/text-embedding-3-small",
        input: .texts(["hello", "world"]),
        dimensions: 256,
        encodingFormat: .float,
        inputType: "search_query"))

    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(request.url.absoluteString, "https://openrouter.ai/api/v1/embeddings")
    let body = try bodyJSON(request)
    XCTAssertEqual(body["input"] as? [String], ["hello", "world"])
    XCTAssertEqual(body["dimensions"] as? Int, 256)
    XCTAssertEqual(body["encoding_format"] as? String, "float")
    XCTAssertEqual(body["input_type"] as? String, "search_query")

    XCTAssertEqual(response.data.first?.embedding.floatsValue, [0.1, -0.2, 0.3])
    XCTAssertEqual(response.usage?.cost, 0.000001)
  }

  func testEmbeddingsModelsPath() async throws {
    mock.enqueueJSON(#"{"data": [{"id": "openai/text-embedding-3-small"}]}"#)
    let models = try await service.embeddingsModels()
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/embeddings/models")
    XCTAssertEqual(models.first?.id, "openai/text-embedding-3-small")
  }

  // MARK: Rerank

  func testRerank() async throws {
    mock.enqueueJSON("""
      {"id": "rr_1", "model": "cohere/rerank-v3.5", "provider": "Cohere",
       "results": [
         {"index": 1, "relevance_score": 0.98, "document": {"text": "swift concurrency"}},
         {"index": 0, "relevance_score": 0.12, "document": {"text": "cooking pasta"}}
       ],
       "usage": {"search_units": 1, "cost": 0.002}}
      """)

    let response = try await service.rerank(
      RerankRequest(
        model: "cohere/rerank-v3.5",
        query: "how does swift concurrency work",
        documents: [.text("cooking pasta"), .text("swift concurrency")],
        topN: 2))

    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["query"] as? String, "how does swift concurrency work")
    XCTAssertEqual(body["documents"] as? [String], ["cooking pasta", "swift concurrency"])
    XCTAssertEqual(body["top_n"] as? Int, 2)

    XCTAssertEqual(response.results.first?.index, 1)
    XCTAssertEqual(response.results.first?.relevanceScore, 0.98)
    XCTAssertEqual(response.usage?.searchUnits, 1)
  }

  // MARK: Presets

  func testPresetsListAndDetail() async throws {
    mock.enqueueJSON("""
      {"data": [{"id": "p_1", "slug": "my-preset", "name": "My Preset", "status": "active"}],
       "total_count": 1}
      """)
    let list = try await service.presets(offset: 10, limit: 5)
    let url = try XCTUnwrap(mock.lastRequest?.url)
    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    XCTAssertEqual(components.path, "/api/v1/presets")
    let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
    XCTAssertEqual(query["offset"], "10")
    XCTAssertEqual(query["limit"], "5")
    XCTAssertEqual(list.data.first?.slug, "my-preset")
    XCTAssertEqual(list.totalCount, 1)

    mock.enqueueJSON("""
      {"data": {"id": "p_1", "slug": "my-preset", "status": "active",
                "designated_version": {"id": "v_2", "preset_id": "p_1", "version": 2,
                                       "config": {"model": "openai/gpt-4o", "temperature": 0.2},
                                       "system_prompt": "Be nice."}}}
      """)
    let detail = try await service.preset(slug: "my-preset")
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/presets/my-preset")
    XCTAssertEqual(detail.designatedVersion?.version, 2)
    XCTAssertEqual(detail.designatedVersion?.config?["model"]?.stringValue, "openai/gpt-4o")
    XCTAssertEqual(detail.designatedVersion?.systemPrompt, "Be nice.")
  }

  func testSavePresetFromChatCompletionReturnsPresetNotCompletion() async throws {
    mock.enqueueJSON(#"{"data": {"id": "p_1", "slug": "fast-summarizer", "status": "active"}}"#)

    let detail = try await service.savePreset(
      slug: "fast-summarizer",
      fromChatCompletion: ChatCompletionRequest(
        model: "openai/gpt-4o",
        messages: [.system("Summarize tersely.")],
        temperature: 0.1))

    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(
      request.url.absoluteString,
      "https://openrouter.ai/api/v1/presets/fast-summarizer/chat/completions")
    XCTAssertEqual(request.method.rawValue, "POST")
    XCTAssertEqual(detail.slug, "fast-summarizer")
  }
}
