import Foundation

// MARK: - OpenRouterModel

/// A model listed by `GET /api/v1/models`.
public struct OpenRouterModel: Decodable, Sendable {
  public let id: String
  public let canonicalSlug: String?
  /// Either a slug string or an object, depending on the model — kept dynamic.
  public let aliasTarget: JSONValue?
  public let name: String?
  public let description: String?
  public let created: Double?
  public let contextLength: Int?
  public let architecture: Architecture?
  public let pricing: Pricing?
  public let topProvider: TopProvider?
  public let supportedParameters: [String]?
  public let defaultParameters: JSONValue?
  public let perRequestLimits: JSONValue?
  public let huggingFaceId: String?
  public let knowledgeCutoff: String?
  public let expirationDate: String?
  public let benchmarks: JSONValue?

  public struct Architecture: Decodable, Sendable {
    public let modality: String?
    public let inputModalities: [String]?
    public let outputModalities: [String]?
    public let tokenizer: String?
    public let instructType: String?

    enum CodingKeys: String, CodingKey {
      case modality
      case inputModalities = "input_modalities"
      case outputModalities = "output_modalities"
      case tokenizer
      case instructType = "instruct_type"
    }
  }

  /// Prices are USD-per-token strings, e.g. `"0.000008"`.
  public struct Pricing: Decodable, Sendable {
    public let prompt: String?
    public let completion: String?
    public let request: String?
    public let image: String?
    public let audio: String?
    public let webSearch: String?
    public let internalReasoning: String?
    public let inputCacheRead: String?
    public let inputCacheWrite: String?

    enum CodingKeys: String, CodingKey {
      case prompt
      case completion
      case request
      case image
      case audio
      case webSearch = "web_search"
      case internalReasoning = "internal_reasoning"
      case inputCacheRead = "input_cache_read"
      case inputCacheWrite = "input_cache_write"
    }
  }

  public struct TopProvider: Decodable, Sendable {
    public let contextLength: Int?
    public let maxCompletionTokens: Int?
    public let isModerated: Bool?

    enum CodingKeys: String, CodingKey {
      case contextLength = "context_length"
      case maxCompletionTokens = "max_completion_tokens"
      case isModerated = "is_moderated"
    }
  }

  enum CodingKeys: String, CodingKey {
    case id
    case canonicalSlug = "canonical_slug"
    case aliasTarget = "alias_target"
    case name
    case description
    case created
    case contextLength = "context_length"
    case architecture
    case pricing
    case topProvider = "top_provider"
    case supportedParameters = "supported_parameters"
    case defaultParameters = "default_parameters"
    case perRequestLimits = "per_request_limits"
    case huggingFaceId = "hugging_face_id"
    case knowledgeCutoff = "knowledge_cutoff"
    case expirationDate = "expiration_date"
    case benchmarks
  }
}

struct ModelsResponse: Decodable {
  let data: [OpenRouterModel]
}

struct SingleModelResponse: Decodable {
  let data: OpenRouterModel
}

// MARK: - ModelEndpointsList

/// Result of `GET /api/v1/models/{author}/{slug}/endpoints`.
public struct ModelEndpointsList: Decodable, Sendable {
  public let id: String?
  public let name: String?
  public let created: Double?
  public let description: String?
  public let architecture: OpenRouterModel.Architecture?
  public let endpoints: [ModelEndpoint]

  public struct ModelEndpoint: Decodable, Sendable {
    public let name: String?
    public let providerName: String?
    public let tag: String?
    public let contextLength: Int?
    public let maxCompletionTokens: Int?
    public let maxPromptTokens: Int?
    public let pricing: JSONValue?
    public let quantization: String?
    public let uptimeLast30m: Double?
    public let supportsImplicitCaching: Bool?
    public let supportedParameters: [String]?
    public let status: JSONValue?

    enum CodingKeys: String, CodingKey {
      case name
      case providerName = "provider_name"
      case tag
      case contextLength = "context_length"
      case maxCompletionTokens = "max_completion_tokens"
      case maxPromptTokens = "max_prompt_tokens"
      case pricing
      case quantization
      case uptimeLast30m = "uptime_last_30m"
      case supportsImplicitCaching = "supports_implicit_caching"
      case supportedParameters = "supported_parameters"
      case status
    }
  }
}

struct ModelEndpointsResponse: Decodable {
  let data: ModelEndpointsList
}

struct ModelsCountResponse: Decodable {
  struct Payload: Decodable {
    let count: Int
  }

  let data: Payload
}
