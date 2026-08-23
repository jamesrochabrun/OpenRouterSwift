import Foundation

// MARK: - EmbeddingsRequest

/// Request body for `POST /api/v1/embeddings`.
public struct EmbeddingsRequest: Encodable, Sendable {
  public enum Input: Encodable, Sendable {
    case text(String)
    case texts([String])
    /// Pre-tokenized input.
    case tokens([Int])
    case tokenBatches([[Int]])
    /// Multimodal input items — encoded verbatim
    /// (`[{"content": [{"type": "text", ...}, {"type": "image_url", ...}]}]`).
    case multimodal(JSONValue)

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .text(let value): try container.encode(value)
      case .texts(let value): try container.encode(value)
      case .tokens(let value): try container.encode(value)
      case .tokenBatches(let value): try container.encode(value)
      case .multimodal(let value): try container.encode(value)
      }
    }
  }

  public enum EncodingFormat: String, Encodable, Sendable {
    case float
    case base64
  }

  public var model: String
  public var input: Input
  public var dimensions: Int?
  public var encodingFormat: EncodingFormat?
  /// e.g. `"search_query"` or `"search_document"`.
  public var inputType: String?
  public var provider: ProviderPreferences?
  public var user: String?
  /// Escape hatch merged into the top-level JSON (typed fields win).
  public var extraBody: [String: JSONValue]?

  public init(
    model: String,
    input: Input,
    dimensions: Int? = nil,
    encodingFormat: EncodingFormat? = nil,
    inputType: String? = nil,
    provider: ProviderPreferences? = nil,
    user: String? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.input = input
    self.dimensions = dimensions
    self.encodingFormat = encodingFormat
    self.inputType = inputType
    self.provider = provider
    self.user = user
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case model
    case input
    case dimensions
    case encodingFormat = "encoding_format"
    case inputType = "input_type"
    case provider
    case user
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
    try container.encode(input, forKey: .input)
    try container.encodeIfPresent(dimensions, forKey: .dimensions)
    try container.encodeIfPresent(encodingFormat, forKey: .encodingFormat)
    try container.encodeIfPresent(inputType, forKey: .inputType)
    try container.encodeIfPresent(provider, forKey: .provider)
    try container.encodeIfPresent(user, forKey: .user)

    if let extraBody {
      let typedKeys = Set(CodingKeys.allCases.map(\.rawValue))
      var dynamic = encoder.container(keyedBy: DynamicKey.self)
      for (key, value) in extraBody where !typedKeys.contains(key) {
        try dynamic.encode(value, forKey: DynamicKey(stringValue: key))
      }
    }
  }
}

// MARK: - EmbeddingsResponse

/// Response from `POST /api/v1/embeddings`.
public struct EmbeddingsResponse: Decodable, Sendable {
  public let object: String?
  public let id: String?
  public let model: String
  public let data: [Embedding]
  public let usage: EmbeddingsUsage?

  public struct Embedding: Decodable, Sendable {
    public let object: String?
    public let index: Int?
    /// Float vector, or a base64 string when `encoding_format: base64` was requested.
    public let embedding: Vector

    public enum Vector: Decodable, Sendable {
      case floats([Double])
      case base64(String)

      public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let floats = try? container.decode([Double].self) {
          self = .floats(floats)
        } else {
          self = .base64(try container.decode(String.self))
        }
      }

      public var floatsValue: [Double]? {
        if case .floats(let value) = self { return value }
        return nil
      }
    }
  }

  public struct EmbeddingsUsage: Decodable, Sendable {
    public let promptTokens: Int?
    public let totalTokens: Int?
    public let cost: Double?
    public let isByok: Bool?

    enum CodingKeys: String, CodingKey {
      case promptTokens = "prompt_tokens"
      case totalTokens = "total_tokens"
      case cost
      case isByok = "is_byok"
    }
  }
}
