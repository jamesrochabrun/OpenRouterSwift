import Foundation

// MARK: - VideoGenerationRequest

/// Request body for `POST /api/v1/videos`. Video generation is asynchronous:
/// the response is a job — poll it with `video(jobId:)` and fetch bytes with
/// `videoContent(jobId:)` once `status == .completed`.
public struct VideoGenerationRequest: Encodable, Sendable {
  public var model: String
  public var prompt: String?
  /// e.g. `"16:9"`, `"9:16"`, `"1:1"`.
  public var aspectRatio: String?
  /// e.g. `"720p"`, `"1080p"`, `"4K"`.
  public var resolution: String?
  /// `"WIDTHxHEIGHT"`.
  public var size: String?
  /// Seconds.
  public var duration: Int?
  public var seed: Int?
  public var generateAudio: Bool?
  /// Webhook called when the job finishes.
  public var callbackURL: String?
  /// First/last frame conditioning: `[{"type": "image_url", "image_url": {"url": ...}, "frame_type": "first_frame"}]`.
  public var frameImages: JSONValue?
  /// Reference inputs (image/audio/video URLs) — encoded verbatim.
  public var inputReferences: JSONValue?
  /// `{"options": {providerSlug: {...}}}` passthrough.
  public var provider: JSONValue?
  /// Escape hatch merged into the top-level JSON (typed fields win).
  public var extraBody: [String: JSONValue]?

  public init(
    model: String,
    prompt: String? = nil,
    aspectRatio: String? = nil,
    resolution: String? = nil,
    size: String? = nil,
    duration: Int? = nil,
    seed: Int? = nil,
    generateAudio: Bool? = nil,
    callbackURL: String? = nil,
    frameImages: JSONValue? = nil,
    inputReferences: JSONValue? = nil,
    provider: JSONValue? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.prompt = prompt
    self.aspectRatio = aspectRatio
    self.resolution = resolution
    self.size = size
    self.duration = duration
    self.seed = seed
    self.generateAudio = generateAudio
    self.callbackURL = callbackURL
    self.frameImages = frameImages
    self.inputReferences = inputReferences
    self.provider = provider
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case model
    case prompt
    case aspectRatio = "aspect_ratio"
    case resolution
    case size
    case duration
    case seed
    case generateAudio = "generate_audio"
    case callbackURL = "callback_url"
    case frameImages = "frame_images"
    case inputReferences = "input_references"
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
    try container.encodeIfPresent(prompt, forKey: .prompt)
    try container.encodeIfPresent(aspectRatio, forKey: .aspectRatio)
    try container.encodeIfPresent(resolution, forKey: .resolution)
    try container.encodeIfPresent(size, forKey: .size)
    try container.encodeIfPresent(duration, forKey: .duration)
    try container.encodeIfPresent(seed, forKey: .seed)
    try container.encodeIfPresent(generateAudio, forKey: .generateAudio)
    try container.encodeIfPresent(callbackURL, forKey: .callbackURL)
    try container.encodeIfPresent(frameImages, forKey: .frameImages)
    try container.encodeIfPresent(inputReferences, forKey: .inputReferences)
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

// MARK: - VideoJob

/// A video generation job (`POST /api/v1/videos` returns 202 with this shape;
/// `GET /api/v1/videos/{jobId}` returns the current state).
public struct VideoJob: Decodable, Sendable {
  public enum Status: String, Decodable, Sendable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
    case cancelled
    case expired
  }

  public let id: String
  public let status: Status
  public let pollingUrl: String?
  /// Use with `generation(id:)` for cost stats.
  public let generationId: String?
  public let error: String?
  public let unsignedUrls: [String]?
  public let usage: JobUsage?

  public struct JobUsage: Decodable, Sendable {
    public let cost: Double?
    public let isByok: Bool?

    enum CodingKeys: String, CodingKey {
      case cost
      case isByok = "is_byok"
    }
  }

  /// Whether the job has reached a terminal state.
  public var isTerminal: Bool {
    switch status {
    case .pending, .inProgress: return false
    case .completed, .failed, .cancelled, .expired: return true
    }
  }

  enum CodingKeys: String, CodingKey {
    case id
    case status
    case pollingUrl = "polling_url"
    case generationId = "generation_id"
    case error
    case unsignedUrls = "unsigned_urls"
    case usage
  }
}

// MARK: - VideoModel

/// A model from `GET /api/v1/videos/models`.
public struct VideoModel: Decodable, Sendable {
  public let id: String
  public let name: String?
  public let canonicalSlug: String?
  public let created: Double?
  public let description: String?
  public let generateAudio: Bool?
  public let supportedAspectRatios: [String]?
  public let supportedDurations: [Int]?
  public let supportedResolutions: [String]?
  public let allowedPassthroughParameters: [String]?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case canonicalSlug = "canonical_slug"
    case created
    case description
    case generateAudio = "generate_audio"
    case supportedAspectRatios = "supported_aspect_ratios"
    case supportedDurations = "supported_durations"
    case supportedResolutions = "supported_resolutions"
    case allowedPassthroughParameters = "allowed_passthrough_parameters"
  }
}

struct VideoModelsResponse: Decodable {
  let data: [VideoModel]
}
