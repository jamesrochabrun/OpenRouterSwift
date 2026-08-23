import Foundation

// MARK: - ResponseInputItem

/// Items in the `input` array of `POST /api/v1/responses`.
public enum ResponseInputItem: Encodable, Sendable {
  case message(role: String, content: MessageContent)
  case functionCall(callId: String, name: String, arguments: String)
  case functionCallOutput(callId: String, output: String)
  /// Echo back a reasoning item (e.g. with `encrypted_content`) — encoded verbatim.
  case other(JSONValue)

  public enum MessageContent: Encodable, Sendable {
    case text(String)
    case parts([ResponseInputContentPart])

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .text(let text): try container.encode(text)
      case .parts(let parts): try container.encode(parts)
      }
    }
  }

  private struct Key: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue _: Int) { nil }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .message(let role, let content):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("message", forKey: Key(stringValue: "type"))
      try container.encode(role, forKey: Key(stringValue: "role"))
      try container.encode(content, forKey: Key(stringValue: "content"))

    case .functionCall(let callId, let name, let arguments):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("function_call", forKey: Key(stringValue: "type"))
      try container.encode(callId, forKey: Key(stringValue: "call_id"))
      try container.encode(name, forKey: Key(stringValue: "name"))
      try container.encode(arguments, forKey: Key(stringValue: "arguments"))

    case .functionCallOutput(let callId, let output):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("function_call_output", forKey: Key(stringValue: "type"))
      try container.encode(callId, forKey: Key(stringValue: "call_id"))
      try container.encode(output, forKey: Key(stringValue: "output"))

    case .other(let value):
      try value.encode(to: encoder)
    }
  }

  public static func user(_ text: String) -> ResponseInputItem { .message(role: "user", content: .text(text)) }
  public static func system(_ text: String) -> ResponseInputItem { .message(role: "system", content: .text(text)) }
  public static func assistant(_ text: String) -> ResponseInputItem { .message(role: "assistant", content: .text(text)) }
}

/// Content parts inside a Responses input message.
public enum ResponseInputContentPart: Encodable, Sendable {
  case inputText(String)
  /// `detail` is required by the spec; `"auto"` is a safe default. Also accepts `"original"`.
  case inputImage(url: String, detail: String = "auto")
  case inputFile(fileData: String? = nil, fileURL: String? = nil, filename: String? = nil)
  case inputAudio(data: String, format: String)
  case other(JSONValue)

  private struct Key: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue _: Int) { nil }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .inputText(let text):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("input_text", forKey: Key(stringValue: "type"))
      try container.encode(text, forKey: Key(stringValue: "text"))

    case .inputImage(let url, let detail):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("input_image", forKey: Key(stringValue: "type"))
      try container.encode(url, forKey: Key(stringValue: "image_url"))
      try container.encode(detail, forKey: Key(stringValue: "detail"))

    case .inputFile(let fileData, let fileURL, let filename):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("input_file", forKey: Key(stringValue: "type"))
      try container.encodeIfPresent(fileData, forKey: Key(stringValue: "file_data"))
      try container.encodeIfPresent(fileURL, forKey: Key(stringValue: "file_url"))
      try container.encodeIfPresent(filename, forKey: Key(stringValue: "filename"))

    case .inputAudio(let data, let format):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("input_audio", forKey: Key(stringValue: "type"))
      try container.encode(
        ["data": JSONValue.string(data), "format": .string(format)],
        forKey: Key(stringValue: "input_audio"))

    case .other(let value):
      try value.encode(to: encoder)
    }
  }
}

// MARK: - Responses config types

/// Reasoning config for `/responses` (superset of the chat `reasoning` object).
public struct ResponsesReasoning: Encodable, Sendable {
  public var effort: Reasoning.Effort?
  public var summary: Reasoning.Summary?
  /// OpenRouter extension: `"standard"` or `"pro"`.
  public var mode: String?
  /// OpenRouter extension: `"auto"`, `"all_turns"`, or `"current_turn"`.
  public var context: String?
  public var enabled: Bool?
  public var maxTokens: Int?

  public init(
    effort: Reasoning.Effort? = nil,
    summary: Reasoning.Summary? = nil,
    mode: String? = nil,
    context: String? = nil,
    enabled: Bool? = nil,
    maxTokens: Int? = nil)
  {
    self.effort = effort
    self.summary = summary
    self.mode = mode
    self.context = context
    self.enabled = enabled
    self.maxTokens = maxTokens
  }

  enum CodingKeys: String, CodingKey {
    case effort
    case summary
    case mode
    case context
    case enabled
    case maxTokens = "max_tokens"
  }
}

/// The `text` config: output format and verbosity.
public struct ResponsesTextConfig: Encodable, Sendable {
  public enum Format: Encodable, Sendable {
    case text
    case jsonObject
    case jsonSchema(name: String, schema: JSONValue, strict: Bool? = nil, description: String? = nil)

    private struct Key: CodingKey {
      var stringValue: String
      var intValue: Int? { nil }
      init(stringValue: String) { self.stringValue = stringValue }
      init?(intValue _: Int) { nil }
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: Key.self)
      switch self {
      case .text:
        try container.encode("text", forKey: Key(stringValue: "type"))

      case .jsonObject:
        try container.encode("json_object", forKey: Key(stringValue: "type"))

      case .jsonSchema(let name, let schema, let strict, let description):
        try container.encode("json_schema", forKey: Key(stringValue: "type"))
        try container.encode(name, forKey: Key(stringValue: "name"))
        try container.encode(schema, forKey: Key(stringValue: "schema"))
        try container.encodeIfPresent(strict, forKey: Key(stringValue: "strict"))
        try container.encodeIfPresent(description, forKey: Key(stringValue: "description"))
      }
    }
  }

  public var format: Format?
  public var verbosity: String?

  public init(format: Format? = nil, verbosity: String? = nil) {
    self.format = format
    self.verbosity = verbosity
  }
}

/// Tools for `/responses` — note the flat shape (`name` at the top level, unlike chat).
public enum ResponsesTool: Encodable, Sendable {
  case function(name: String, parameters: JSONValue?, description: String? = nil, strict: Bool? = nil)
  case other(JSONValue)

  private struct Key: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue _: Int) { nil }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .function(let name, let parameters, let description, let strict):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("function", forKey: Key(stringValue: "type"))
      try container.encode(name, forKey: Key(stringValue: "name"))
      try container.encode(parameters ?? .null, forKey: Key(stringValue: "parameters"))
      try container.encodeIfPresent(description, forKey: Key(stringValue: "description"))
      try container.encodeIfPresent(strict, forKey: Key(stringValue: "strict"))

    case .other(let value):
      try value.encode(to: encoder)
    }
  }
}

public enum ResponsesToolChoice: Encodable, Sendable {
  case auto
  case none
  case required
  case function(name: String)
  case other(JSONValue)

  private struct Key: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue _: Int) { nil }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .auto:
      var container = encoder.singleValueContainer()
      try container.encode("auto")

    case .none:
      var container = encoder.singleValueContainer()
      try container.encode("none")

    case .required:
      var container = encoder.singleValueContainer()
      try container.encode("required")

    case .function(let name):
      var container = encoder.container(keyedBy: Key.self)
      try container.encode("function", forKey: Key(stringValue: "type"))
      try container.encode(name, forKey: Key(stringValue: "name"))

    case .other(let value):
      try value.encode(to: encoder)
    }
  }
}

// MARK: - ResponsesRequest

/// Request body for `POST /api/v1/responses` (OpenResponses).
///
/// OpenRouter's implementation is **stateless**: `store: true` and non-null
/// `previous_response_id` are rejected with 400, so this type intentionally omits both.
/// Persist reasoning across turns by echoing `reasoning`/`encrypted_content` output items
/// back via `.other` input items.
public struct ResponsesRequest: Encodable, Sendable {
  public enum Input: Encodable, Sendable {
    case text(String)
    case items([ResponseInputItem])

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .text(let text): try container.encode(text)
      case .items(let items): try container.encode(items)
      }
    }
  }

  public var model: String?
  /// Fallback model list.
  public var models: [String]?
  public var input: Input
  public var instructions: String?
  public var maxOutputTokens: Int?
  /// Server-tool agent step cap (default 30).
  public var maxToolCalls: Int?
  public var include: [String]?
  public var metadata: [String: String]?
  public var modalities: [String]?
  public var parallelToolCalls: Bool?
  public var stream: Bool?
  public var reasoning: ResponsesReasoning?
  public var text: ResponsesTextConfig?
  public var toolChoice: ResponsesToolChoice?
  public var tools: [ResponsesTool]?
  public var truncation: String?
  public var temperature: Double?
  public var topP: Double?
  public var topK: Int?
  public var frequencyPenalty: Double?
  public var presencePenalty: Double?
  public var topLogprobs: Int?
  public var promptCacheKey: String?
  public var promptCacheOptions: JSONValue?
  public var safetyIdentifier: String?
  public var serviceTier: String?

  // OpenRouter extensions
  public var provider: ProviderPreferences?
  public var plugins: [Plugin]?
  public var sessionId: String?
  public var trace: Trace?
  public var cacheControl: CacheControl?
  public var imageConfig: JSONValue?
  public var user: String?

  /// Escape hatch merged into the top-level JSON (typed fields win).
  public var extraBody: [String: JSONValue]?

  public init(
    model: String? = nil,
    models: [String]? = nil,
    input: Input,
    instructions: String? = nil,
    maxOutputTokens: Int? = nil,
    maxToolCalls: Int? = nil,
    include: [String]? = nil,
    metadata: [String: String]? = nil,
    modalities: [String]? = nil,
    parallelToolCalls: Bool? = nil,
    stream: Bool? = nil,
    reasoning: ResponsesReasoning? = nil,
    text: ResponsesTextConfig? = nil,
    toolChoice: ResponsesToolChoice? = nil,
    tools: [ResponsesTool]? = nil,
    truncation: String? = nil,
    temperature: Double? = nil,
    topP: Double? = nil,
    topK: Int? = nil,
    frequencyPenalty: Double? = nil,
    presencePenalty: Double? = nil,
    topLogprobs: Int? = nil,
    promptCacheKey: String? = nil,
    promptCacheOptions: JSONValue? = nil,
    safetyIdentifier: String? = nil,
    serviceTier: String? = nil,
    provider: ProviderPreferences? = nil,
    plugins: [Plugin]? = nil,
    sessionId: String? = nil,
    trace: Trace? = nil,
    cacheControl: CacheControl? = nil,
    imageConfig: JSONValue? = nil,
    user: String? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.models = models
    self.input = input
    self.instructions = instructions
    self.maxOutputTokens = maxOutputTokens
    self.maxToolCalls = maxToolCalls
    self.include = include
    self.metadata = metadata
    self.modalities = modalities
    self.parallelToolCalls = parallelToolCalls
    self.stream = stream
    self.reasoning = reasoning
    self.text = text
    self.toolChoice = toolChoice
    self.tools = tools
    self.truncation = truncation
    self.temperature = temperature
    self.topP = topP
    self.topK = topK
    self.frequencyPenalty = frequencyPenalty
    self.presencePenalty = presencePenalty
    self.topLogprobs = topLogprobs
    self.promptCacheKey = promptCacheKey
    self.promptCacheOptions = promptCacheOptions
    self.safetyIdentifier = safetyIdentifier
    self.serviceTier = serviceTier
    self.provider = provider
    self.plugins = plugins
    self.sessionId = sessionId
    self.trace = trace
    self.cacheControl = cacheControl
    self.imageConfig = imageConfig
    self.user = user
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case model
    case models
    case input
    case instructions
    case maxOutputTokens = "max_output_tokens"
    case maxToolCalls = "max_tool_calls"
    case include
    case metadata
    case modalities
    case parallelToolCalls = "parallel_tool_calls"
    case stream
    case reasoning
    case text
    case toolChoice = "tool_choice"
    case tools
    case truncation
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case frequencyPenalty = "frequency_penalty"
    case presencePenalty = "presence_penalty"
    case topLogprobs = "top_logprobs"
    case promptCacheKey = "prompt_cache_key"
    case promptCacheOptions = "prompt_cache_options"
    case safetyIdentifier = "safety_identifier"
    case serviceTier = "service_tier"
    case provider
    case plugins
    case sessionId = "session_id"
    case trace
    case cacheControl = "cache_control"
    case imageConfig = "image_config"
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
    try container.encodeIfPresent(model, forKey: .model)
    try container.encodeIfPresent(models, forKey: .models)
    try container.encode(input, forKey: .input)
    try container.encodeIfPresent(instructions, forKey: .instructions)
    try container.encodeIfPresent(maxOutputTokens, forKey: .maxOutputTokens)
    try container.encodeIfPresent(maxToolCalls, forKey: .maxToolCalls)
    try container.encodeIfPresent(include, forKey: .include)
    try container.encodeIfPresent(metadata, forKey: .metadata)
    try container.encodeIfPresent(modalities, forKey: .modalities)
    try container.encodeIfPresent(parallelToolCalls, forKey: .parallelToolCalls)
    try container.encodeIfPresent(stream, forKey: .stream)
    try container.encodeIfPresent(reasoning, forKey: .reasoning)
    try container.encodeIfPresent(text, forKey: .text)
    try container.encodeIfPresent(toolChoice, forKey: .toolChoice)
    try container.encodeIfPresent(tools, forKey: .tools)
    try container.encodeIfPresent(truncation, forKey: .truncation)
    try container.encodeIfPresent(temperature, forKey: .temperature)
    try container.encodeIfPresent(topP, forKey: .topP)
    try container.encodeIfPresent(topK, forKey: .topK)
    try container.encodeIfPresent(frequencyPenalty, forKey: .frequencyPenalty)
    try container.encodeIfPresent(presencePenalty, forKey: .presencePenalty)
    try container.encodeIfPresent(topLogprobs, forKey: .topLogprobs)
    try container.encodeIfPresent(promptCacheKey, forKey: .promptCacheKey)
    try container.encodeIfPresent(promptCacheOptions, forKey: .promptCacheOptions)
    try container.encodeIfPresent(safetyIdentifier, forKey: .safetyIdentifier)
    try container.encodeIfPresent(serviceTier, forKey: .serviceTier)
    try container.encodeIfPresent(provider, forKey: .provider)
    try container.encodeIfPresent(plugins, forKey: .plugins)
    try container.encodeIfPresent(sessionId, forKey: .sessionId)
    try container.encodeIfPresent(trace, forKey: .trace)
    try container.encodeIfPresent(cacheControl, forKey: .cacheControl)
    try container.encodeIfPresent(imageConfig, forKey: .imageConfig)
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
