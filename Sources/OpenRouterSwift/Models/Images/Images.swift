import Foundation

// MARK: - ImageGenerationRequest

/// Request body for `POST /api/v1/images`.
public struct ImageGenerationRequest: Encodable, Sendable {
  /// Provider routing for image models (smaller surface than chat's `provider`).
  public struct ImageProviderPreferences: Encodable, Sendable {
    public var allowFallbacks: Bool?
    public var order: [String]?
    public var only: [String]?
    public var ignore: [String]?
    public var sort: String?
    /// Provider-specific passthrough options, keyed by provider slug.
    public var options: JSONValue?

    public init(
      allowFallbacks: Bool? = nil,
      order: [String]? = nil,
      only: [String]? = nil,
      ignore: [String]? = nil,
      sort: String? = nil,
      options: JSONValue? = nil)
    {
      self.allowFallbacks = allowFallbacks
      self.order = order
      self.only = only
      self.ignore = ignore
      self.sort = sort
      self.options = options
    }

    enum CodingKeys: String, CodingKey {
      case allowFallbacks = "allow_fallbacks"
      case order
      case only
      case ignore
      case sort
      case options
    }
  }

  public var model: String
  public var prompt: String
  /// e.g. `"1:1"`, `"16:9"`, `"auto"`.
  public var aspectRatio: String?
  /// `"auto"`, `"transparent"`, or `"opaque"`.
  public var background: String?
  /// Reference image URLs (https or `data:` URIs) for editing/variation.
  public var inputReferences: [String]?
  /// Number of images (1–10).
  public var n: Int?
  /// 0–100.
  public var outputCompression: Int?
  /// `"png"`, `"jpeg"`, `"webp"`, `"svg"`.
  public var outputFormat: String?
  public var provider: ImageProviderPreferences?
  /// `"auto"`, `"low"`, `"medium"`, `"high"`.
  public var quality: String?
  /// `"512"`, `"1K"`, `"2K"`, `"4K"`.
  public var resolution: String?
  public var seed: Int?
  /// Size tier or `"WIDTHxHEIGHT"`.
  public var size: String?
  public var stream: Bool?
  /// Escape hatch merged into the top-level JSON (typed fields win).
  public var extraBody: [String: JSONValue]?

  public init(
    model: String,
    prompt: String,
    aspectRatio: String? = nil,
    background: String? = nil,
    inputReferences: [String]? = nil,
    n: Int? = nil,
    outputCompression: Int? = nil,
    outputFormat: String? = nil,
    provider: ImageProviderPreferences? = nil,
    quality: String? = nil,
    resolution: String? = nil,
    seed: Int? = nil,
    size: String? = nil,
    stream: Bool? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.prompt = prompt
    self.aspectRatio = aspectRatio
    self.background = background
    self.inputReferences = inputReferences
    self.n = n
    self.outputCompression = outputCompression
    self.outputFormat = outputFormat
    self.provider = provider
    self.quality = quality
    self.resolution = resolution
    self.seed = seed
    self.size = size
    self.stream = stream
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case model
    case prompt
    case aspectRatio = "aspect_ratio"
    case background
    case inputReferences = "input_references"
    case n
    case outputCompression = "output_compression"
    case outputFormat = "output_format"
    case provider
    case quality
    case resolution
    case seed
    case size
    case stream
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
    try container.encode(prompt, forKey: .prompt)
    try container.encodeIfPresent(aspectRatio, forKey: .aspectRatio)
    try container.encodeIfPresent(background, forKey: .background)
    if let inputReferences {
      let items = inputReferences.map { url in
        JSONValue.object(["type": .string("image_url"), "image_url": .object(["url": .string(url)])])
      }
      try container.encode(items, forKey: .inputReferences)
    }
    try container.encodeIfPresent(n, forKey: .n)
    try container.encodeIfPresent(outputCompression, forKey: .outputCompression)
    try container.encodeIfPresent(outputFormat, forKey: .outputFormat)
    try container.encodeIfPresent(provider, forKey: .provider)
    try container.encodeIfPresent(quality, forKey: .quality)
    try container.encodeIfPresent(resolution, forKey: .resolution)
    try container.encodeIfPresent(seed, forKey: .seed)
    try container.encodeIfPresent(size, forKey: .size)
    try container.encodeIfPresent(stream, forKey: .stream)

    if let extraBody {
      let typedKeys = Set(CodingKeys.allCases.map(\.rawValue))
      var dynamic = encoder.container(keyedBy: DynamicKey.self)
      for (key, value) in extraBody where !typedKeys.contains(key) {
        try dynamic.encode(value, forKey: DynamicKey(stringValue: key))
      }
    }
  }
}

// MARK: - ImageGenerationResponse

/// Response from `POST /api/v1/images` (non-streaming).
public struct ImageGenerationResponse: Decodable, Sendable {
  public let created: Double?
  public let data: [GeneratedImage]
  public let usage: ImageUsage?

  public struct GeneratedImage: Decodable, Sendable {
    /// Base64-encoded image bytes.
    public let b64Json: String
    public let mediaType: String?

    /// Decoded image bytes.
    public var imageData: Data? {
      Data(base64Encoded: b64Json)
    }

    enum CodingKeys: String, CodingKey {
      case b64Json = "b64_json"
      case mediaType = "media_type"
    }
  }

  public struct ImageUsage: Decodable, Sendable {
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?
    public let cost: Double?
    public let isByok: Bool?

    enum CodingKeys: String, CodingKey {
      case promptTokens = "prompt_tokens"
      case completionTokens = "completion_tokens"
      case totalTokens = "total_tokens"
      case cost
      case isByok = "is_byok"
    }
  }
}

// MARK: - ImageStreamEvent

/// SSE events from `POST /api/v1/images` with `stream: true`.
public enum ImageStreamEvent: Decodable, Sendable {
  case partialImage(b64Json: String, index: Int)
  /// `phase` is `"content"`, `"reasoning"`, or `"draft"`.
  case textChunk(text: String, phase: String?)
  case completed(b64Json: String, mediaType: String?, usage: ImageGenerationResponse.ImageUsage?)
  case other(type: String, JSONValue)

  private enum TypeKey: String, CodingKey {
    case type
  }

  private struct Partial: Decodable {
    let b64Json: String
    let partialImageIndex: Int

    enum CodingKeys: String, CodingKey {
      case b64Json = "b64_json"
      case partialImageIndex = "partial_image_index"
    }
  }

  private struct Chunk: Decodable {
    let text: String
    let phase: String?
  }

  private struct Completed: Decodable {
    let b64Json: String
    let mediaType: String?
    let usage: ImageGenerationResponse.ImageUsage?

    enum CodingKeys: String, CodingKey {
      case b64Json = "b64_json"
      case mediaType = "media_type"
      case usage
    }
  }

  public init(from decoder: Decoder) throws {
    let typeContainer = try decoder.container(keyedBy: TypeKey.self)
    let type = try typeContainer.decode(String.self, forKey: .type)
    let single = try decoder.singleValueContainer()
    switch type {
    case "image_generation.partial_image":
      let event = try single.decode(Partial.self)
      self = .partialImage(b64Json: event.b64Json, index: event.partialImageIndex)

    case "image_generation.text_chunk":
      let event = try single.decode(Chunk.self)
      self = .textChunk(text: event.text, phase: event.phase)

    case "image_generation.completed":
      let event = try single.decode(Completed.self)
      self = .completed(b64Json: event.b64Json, mediaType: event.mediaType, usage: event.usage)

    default:
      self = .other(type: type, try single.decode(JSONValue.self))
    }
  }
}

// MARK: - ImageModel

/// A model from `GET /api/v1/images/models`. Note: `supported_parameters` here is a map of
/// parameter descriptors (enum/range/boolean), not the string array used by text models.
public struct ImageModel: Decodable, Sendable {
  public let id: String
  public let name: String?
  public let description: String?
  public let created: Double?
  public let architecture: OpenRouterModel.Architecture?
  public let supportedParameters: JSONValue?
  public let supportsStreaming: Bool?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case created
    case architecture
    case supportedParameters = "supported_parameters"
    case supportsStreaming = "supports_streaming"
  }
}

struct ImageModelsResponse: Decodable {
  let data: [ImageModel]
}

/// Result of `GET /api/v1/images/models/{author}/{slug}/endpoints`.
public struct ImageModelEndpointsList: Decodable, Sendable {
  public let id: String?
  public let endpoints: [Endpoint]

  public struct Endpoint: Decodable, Sendable {
    public let providerName: String?
    public let providerSlug: String?
    public let providerTag: String?
    public let allowedPassthroughParameters: [String]?
    /// Per-unit pricing rows (`billable`, `unit`, `cost_usd`).
    public let pricing: JSONValue?
    public let supportedParameters: JSONValue?
    public let supportsStreaming: Bool?

    enum CodingKeys: String, CodingKey {
      case providerName = "provider_name"
      case providerSlug = "provider_slug"
      case providerTag = "provider_tag"
      case allowedPassthroughParameters = "allowed_passthrough_parameters"
      case pricing
      case supportedParameters = "supported_parameters"
      case supportsStreaming = "supports_streaming"
    }
  }
}
