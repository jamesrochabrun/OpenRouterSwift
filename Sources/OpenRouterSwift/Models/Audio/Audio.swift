import Foundation

// MARK: - AudioSpeechRequest

/// Request body for `POST /api/v1/audio/speech` (TTS). The response is raw audio bytes.
public struct AudioSpeechRequest: Encodable, Sendable {
  public enum ResponseFormat: String, Encodable, Sendable {
    case mp3
    case pcm
  }

  public var model: String
  /// The text to synthesize.
  public var input: String
  /// Provider-specific voice id.
  public var voice: String?
  public var responseFormat: ResponseFormat?
  public var speed: Double?
  /// Voice-cloning references — encoded verbatim
  /// (`[{"type": "input_audio", "input_audio": {"data": ..., "format": ...}}]`).
  public var inputReferences: JSONValue?
  /// `{"options": {providerSlug: {...}}}` passthrough.
  public var provider: JSONValue?
  /// Escape hatch merged into the top-level JSON (typed fields win).
  public var extraBody: [String: JSONValue]?

  public init(
    model: String,
    input: String,
    voice: String? = nil,
    responseFormat: ResponseFormat? = nil,
    speed: Double? = nil,
    inputReferences: JSONValue? = nil,
    provider: JSONValue? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.input = input
    self.voice = voice
    self.responseFormat = responseFormat
    self.speed = speed
    self.inputReferences = inputReferences
    self.provider = provider
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case model
    case input
    case voice
    case responseFormat = "response_format"
    case speed
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
    try container.encode(input, forKey: .input)
    try container.encodeIfPresent(voice, forKey: .voice)
    try container.encodeIfPresent(responseFormat, forKey: .responseFormat)
    try container.encodeIfPresent(speed, forKey: .speed)
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

// MARK: - AudioTranscriptionRequest

/// JSON-mode request body for `POST /api/v1/audio/transcriptions` (STT).
/// For file uploads use `audioTranscription(fileData:filename:...)` (multipart).
public struct AudioTranscriptionRequest: Encodable, Sendable {
  public struct InputAudio: Encodable, Sendable {
    /// Base64-encoded raw audio (not a data URI).
    public var data: String
    /// `wav`, `mp3`, `flac`, `m4a`, `ogg`, `webm`, `aac`.
    public var format: String

    public init(data: String, format: String) {
      self.data = data
      self.format = format
    }
  }

  public enum ResponseFormat: String, Encodable, Sendable {
    case json
    case verboseJson = "verbose_json"
  }

  public var model: String
  public var inputAudio: InputAudio
  /// ISO-639-1 code.
  public var language: String?
  public var responseFormat: ResponseFormat?
  public var temperature: Double?
  /// `"word"` / `"segment"`.
  public var timestampGranularities: [String]?
  public var provider: JSONValue?

  public init(
    model: String,
    inputAudio: InputAudio,
    language: String? = nil,
    responseFormat: ResponseFormat? = nil,
    temperature: Double? = nil,
    timestampGranularities: [String]? = nil,
    provider: JSONValue? = nil)
  {
    self.model = model
    self.inputAudio = inputAudio
    self.language = language
    self.responseFormat = responseFormat
    self.temperature = temperature
    self.timestampGranularities = timestampGranularities
    self.provider = provider
  }

  enum CodingKeys: String, CodingKey {
    case model
    case inputAudio = "input_audio"
    case language
    case responseFormat = "response_format"
    case temperature
    case timestampGranularities = "timestamp_granularities"
    case provider
  }
}

// MARK: - AudioTranscription

/// Response from `POST /api/v1/audio/transcriptions`.
public struct AudioTranscription: Decodable, Sendable {
  public let text: String
  public let language: String?
  public let duration: Double?
  public let task: String?
  public let segments: [Segment]?
  public let words: [Word]?
  public let usage: TranscriptionUsage?

  public struct Segment: Decodable, Sendable {
    public let id: Int?
    public let start: Double?
    public let end: Double?
    public let text: String?
    public let speaker: Int?
  }

  public struct Word: Decodable, Sendable {
    public let word: String?
    public let start: Double?
    public let end: Double?
    public let speaker: Int?
  }

  public struct TranscriptionUsage: Decodable, Sendable {
    public let cost: Double?
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let totalTokens: Int?
    public let seconds: Double?

    enum CodingKeys: String, CodingKey {
      case cost
      case inputTokens = "input_tokens"
      case outputTokens = "output_tokens"
      case totalTokens = "total_tokens"
      case seconds
    }
  }
}
