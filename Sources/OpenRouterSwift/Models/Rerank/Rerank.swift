import Foundation

// MARK: - RerankRequest

/// Request body for `POST /api/v1/rerank`.
public struct RerankRequest: Encodable, Sendable {
  public enum Document: Encodable, Sendable {
    case text(String)
    /// Object form: at least one of `text` / `image` (http(s) URL or `data:` URI).
    case object(text: String? = nil, image: String? = nil)

    private struct Key: CodingKey {
      var stringValue: String
      var intValue: Int? { nil }
      init(stringValue: String) { self.stringValue = stringValue }
      init?(intValue _: Int) { nil }
    }

    public func encode(to encoder: Encoder) throws {
      switch self {
      case .text(let value):
        var container = encoder.singleValueContainer()
        try container.encode(value)

      case .object(let text, let image):
        var container = encoder.container(keyedBy: Key.self)
        try container.encodeIfPresent(text, forKey: Key(stringValue: "text"))
        try container.encodeIfPresent(image, forKey: Key(stringValue: "image"))
      }
    }
  }

  public var model: String
  public var query: String
  public var documents: [Document]
  public var topN: Int?
  public var provider: ProviderPreferences?
  /// Escape hatch merged into the top-level JSON (typed fields win).
  public var extraBody: [String: JSONValue]?

  public init(
    model: String,
    query: String,
    documents: [Document],
    topN: Int? = nil,
    provider: ProviderPreferences? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.query = query
    self.documents = documents
    self.topN = topN
    self.provider = provider
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case model
    case query
    case documents
    case topN = "top_n"
    case provider
  }

  private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue _: Int) { nil }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(model, forKey: .model)
    try container.encode(query, forKey: .query)
    try container.encode(documents, forKey: .documents)
    try container.encodeIfPresent(topN, forKey: .topN)
    try container.encodeIfPresent(provider, forKey: .provider)

    if let extraBody {
      let typedKeys = Set(CodingKeys.allCases.map(\.rawValue))
      var dynamic = encoder.container(keyedBy: DynamicKey.self)
      for (key, value) in extraBody where !typedKeys.contains(key) {
        try dynamic.encode(value, forKey: DynamicKey(stringValue: key))
      }
    }
  }
}

// MARK: - RerankResponse

/// Response from `POST /api/v1/rerank`. Results are sorted by relevance.
public struct RerankResponse: Decodable, Sendable {
  public let id: String?
  public let model: String
  public let provider: String?
  public let results: [Result]
  public let usage: RerankUsage?

  public struct Result: Decodable, Sendable {
    /// Index into the original `documents` array.
    public let index: Int
    public let relevanceScore: Double
    public let document: Document?

    public struct Document: Decodable, Sendable {
      public let text: String?
      public let image: String?
    }

    enum CodingKeys: String, CodingKey {
      case index
      case relevanceScore = "relevance_score"
      case document
    }
  }

  public struct RerankUsage: Decodable, Sendable {
    public let totalTokens: Int?
    public let cost: Double?
    public let searchUnits: Int?

    enum CodingKeys: String, CodingKey {
      case totalTokens = "total_tokens"
      case cost
      case searchUnits = "search_units"
    }
  }
}
