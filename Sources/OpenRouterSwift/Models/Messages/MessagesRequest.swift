import Foundation

// MARK: - AnthropicMessage

/// A message in OpenRouter's Anthropic-format `/messages` endpoint.
public struct AnthropicMessage: Encodable, Sendable {
  public enum Role: String, Encodable, Sendable {
    case user
    case assistant
    case system
  }

  public enum Content: Encodable, Sendable {
    case text(String)
    case blocks([AnthropicContentBlock])

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .text(let text): try container.encode(text)
      case .blocks(let blocks): try container.encode(blocks)
      }
    }
  }

  public var role: Role
  public var content: Content

  public init(role: Role, content: Content) {
    self.role = role
    self.content = content
  }

  public static func user(_ text: String) -> AnthropicMessage { .init(role: .user, content: .text(text)) }
  public static func assistant(_ text: String) -> AnthropicMessage { .init(role: .assistant, content: .text(text)) }
}

// MARK: - AnthropicContentBlock (input)

/// Input content blocks for `/messages`. Blocks this package doesn't model yet
/// can be sent via `.other(JSONValue)`.
public enum AnthropicContentBlock: Encodable, Sendable {
  case text(String, cacheControl: CacheControl? = nil)
  /// Base64 image: `mediaType` e.g. `"image/png"`.
  case imageBase64(mediaType: String, data: String, cacheControl: CacheControl? = nil)
  case imageURL(String, cacheControl: CacheControl? = nil)
  /// PDF document by URL.
  case documentURL(String, title: String? = nil, cacheControl: CacheControl? = nil)
  /// PDF document as base64 (`media_type: application/pdf`).
  case documentBase64(mediaType: String, data: String, title: String? = nil, cacheControl: CacheControl? = nil)
  case toolUse(id: String, name: String, input: JSONValue)
  case toolResult(toolUseId: String, content: String, isError: Bool? = nil)
  case thinking(String, signature: String)
  case redactedThinking(data: String)
  /// Escape hatch for any other block shape — encoded verbatim.
  case other(JSONValue)

  private struct Key: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue _: Int) { nil }
  }

  private func key(_ name: String) -> Key { Key(stringValue: name) }

  public func encode(to encoder: Encoder) throws {
    if case .other(let value) = self {
      try value.encode(to: encoder)
      return
    }
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .text(let text, let cacheControl):
      try container.encode("text", forKey: key("type"))
      try container.encode(text, forKey: key("text"))
      try container.encodeIfPresent(cacheControl, forKey: key("cache_control"))

    case .imageBase64(let mediaType, let data, let cacheControl):
      try container.encode("image", forKey: key("type"))
      try container.encode(
        ["type": JSONValue.string("base64"), "media_type": .string(mediaType), "data": .string(data)],
        forKey: key("source"))
      try container.encodeIfPresent(cacheControl, forKey: key("cache_control"))

    case .imageURL(let url, let cacheControl):
      try container.encode("image", forKey: key("type"))
      try container.encode(
        ["type": JSONValue.string("url"), "url": .string(url)],
        forKey: key("source"))
      try container.encodeIfPresent(cacheControl, forKey: key("cache_control"))

    case .documentURL(let url, let title, let cacheControl):
      try container.encode("document", forKey: key("type"))
      try container.encode(
        ["type": JSONValue.string("url"), "url": .string(url)],
        forKey: key("source"))
      try container.encodeIfPresent(title, forKey: key("title"))
      try container.encodeIfPresent(cacheControl, forKey: key("cache_control"))

    case .documentBase64(let mediaType, let data, let title, let cacheControl):
      try container.encode("document", forKey: key("type"))
      try container.encode(
        ["type": JSONValue.string("base64"), "media_type": .string(mediaType), "data": .string(data)],
        forKey: key("source"))
      try container.encodeIfPresent(title, forKey: key("title"))
      try container.encodeIfPresent(cacheControl, forKey: key("cache_control"))

    case .toolUse(let id, let name, let input):
      try container.encode("tool_use", forKey: key("type"))
      try container.encode(id, forKey: key("id"))
      try container.encode(name, forKey: key("name"))
      try container.encode(input, forKey: key("input"))

    case .toolResult(let toolUseId, let content, let isError):
      try container.encode("tool_result", forKey: key("type"))
      try container.encode(toolUseId, forKey: key("tool_use_id"))
      try container.encode(content, forKey: key("content"))
      try container.encodeIfPresent(isError, forKey: key("is_error"))

    case .thinking(let thinking, let signature):
      try container.encode("thinking", forKey: key("type"))
      try container.encode(thinking, forKey: key("thinking"))
      try container.encode(signature, forKey: key("signature"))

    case .redactedThinking(let data):
      try container.encode("redacted_thinking", forKey: key("type"))
      try container.encode(data, forKey: key("data"))

    case .other:
      break
    }
  }
}

// MARK: - Thinking

/// Extended-thinking configuration for `/messages`.
public enum Thinking: Encodable, Sendable {
  case enabled(budgetTokens: Int, display: String? = nil)
  case disabled
  case adaptive(display: String? = nil)

  enum CodingKeys: String, CodingKey {
    case type
    case budgetTokens = "budget_tokens"
    case display
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .enabled(let budgetTokens, let display):
      try container.encode("enabled", forKey: .type)
      try container.encode(budgetTokens, forKey: .budgetTokens)
      try container.encodeIfPresent(display, forKey: .display)

    case .disabled:
      try container.encode("disabled", forKey: .type)

    case .adaptive(let display):
      try container.encode("adaptive", forKey: .type)
      try container.encodeIfPresent(display, forKey: .display)
    }
  }
}

// MARK: - AnthropicTool / AnthropicToolChoice

public enum AnthropicTool: Encodable, Sendable {
  /// A custom function tool: `inputSchema` is the JSON Schema of the arguments.
  case custom(name: String, inputSchema: JSONValue, description: String? = nil, cacheControl: CacheControl? = nil)
  /// Server tools and anything else — encoded verbatim.
  case other(JSONValue)

  enum CodingKeys: String, CodingKey {
    case name
    case description
    case inputSchema = "input_schema"
    case cacheControl = "cache_control"
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .custom(let name, let inputSchema, let description, let cacheControl):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
      try container.encode(inputSchema, forKey: .inputSchema)
      try container.encodeIfPresent(description, forKey: .description)
      try container.encodeIfPresent(cacheControl, forKey: .cacheControl)

    case .other(let value):
      try value.encode(to: encoder)
    }
  }
}

public enum AnthropicToolChoice: Encodable, Sendable {
  case auto(disableParallelToolUse: Bool? = nil)
  case any(disableParallelToolUse: Bool? = nil)
  case none
  case tool(name: String, disableParallelToolUse: Bool? = nil)

  enum CodingKeys: String, CodingKey {
    case type
    case name
    case disableParallelToolUse = "disable_parallel_tool_use"
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .auto(let disable):
      try container.encode("auto", forKey: .type)
      try container.encodeIfPresent(disable, forKey: .disableParallelToolUse)

    case .any(let disable):
      try container.encode("any", forKey: .type)
      try container.encodeIfPresent(disable, forKey: .disableParallelToolUse)

    case .none:
      try container.encode("none", forKey: .type)

    case .tool(let name, let disable):
      try container.encode("tool", forKey: .type)
      try container.encode(name, forKey: .name)
      try container.encodeIfPresent(disable, forKey: .disableParallelToolUse)
    }
  }
}

// MARK: - MessagesRequest

/// Request body for `POST /api/v1/messages` (Anthropic Messages format + OpenRouter extensions).
///
/// Per the OpenRouter spec only `model` and `messages` are required; note that many
/// Anthropic-family providers still expect `maxTokens`.
public struct MessagesRequest: Encodable, Sendable {
  public var model: String
  public var messages: [AnthropicMessage]
  public var maxTokens: Int?
  public var system: String?
  public var metadata: JSONValue?
  public var stopSequences: [String]?
  public var stream: Bool?
  public var temperature: Double?
  public var topK: Int?
  public var topP: Double?
  public var thinking: Thinking?
  public var tools: [AnthropicTool]?
  public var toolChoice: AnthropicToolChoice?
  /// Structured output config: `{effort, format: {type: "json_schema", schema}}`.
  public var outputConfig: JSONValue?
  public var cacheControl: CacheControl?
  public var serviceTier: String?

  // OpenRouter extensions
  /// Fallback model list.
  public var models: [String]?
  public var provider: ProviderPreferences?
  public var plugins: [Plugin]?
  public var sessionId: String?
  public var trace: Trace?
  public var user: String?

  /// Escape hatch merged into the top-level JSON (typed fields win).
  public var extraBody: [String: JSONValue]?

  public init(
    model: String,
    messages: [AnthropicMessage],
    maxTokens: Int? = nil,
    system: String? = nil,
    metadata: JSONValue? = nil,
    stopSequences: [String]? = nil,
    stream: Bool? = nil,
    temperature: Double? = nil,
    topK: Int? = nil,
    topP: Double? = nil,
    thinking: Thinking? = nil,
    tools: [AnthropicTool]? = nil,
    toolChoice: AnthropicToolChoice? = nil,
    outputConfig: JSONValue? = nil,
    cacheControl: CacheControl? = nil,
    serviceTier: String? = nil,
    models: [String]? = nil,
    provider: ProviderPreferences? = nil,
    plugins: [Plugin]? = nil,
    sessionId: String? = nil,
    trace: Trace? = nil,
    user: String? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.messages = messages
    self.maxTokens = maxTokens
    self.system = system
    self.metadata = metadata
    self.stopSequences = stopSequences
    self.stream = stream
    self.temperature = temperature
    self.topK = topK
    self.topP = topP
    self.thinking = thinking
    self.tools = tools
    self.toolChoice = toolChoice
    self.outputConfig = outputConfig
    self.cacheControl = cacheControl
    self.serviceTier = serviceTier
    self.models = models
    self.provider = provider
    self.plugins = plugins
    self.sessionId = sessionId
    self.trace = trace
    self.user = user
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case model
    case messages
    case maxTokens = "max_tokens"
    case system
    case metadata
    case stopSequences = "stop_sequences"
    case stream
    case temperature
    case topK = "top_k"
    case topP = "top_p"
    case thinking
    case tools
    case toolChoice = "tool_choice"
    case outputConfig = "output_config"
    case cacheControl = "cache_control"
    case serviceTier = "service_tier"
    case models
    case provider
    case plugins
    case sessionId = "session_id"
    case trace
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
    try container.encode(messages, forKey: .messages)
    try container.encodeIfPresent(maxTokens, forKey: .maxTokens)
    try container.encodeIfPresent(system, forKey: .system)
    try container.encodeIfPresent(metadata, forKey: .metadata)
    try container.encodeIfPresent(stopSequences, forKey: .stopSequences)
    try container.encodeIfPresent(stream, forKey: .stream)
    try container.encodeIfPresent(temperature, forKey: .temperature)
    try container.encodeIfPresent(topK, forKey: .topK)
    try container.encodeIfPresent(topP, forKey: .topP)
    try container.encodeIfPresent(thinking, forKey: .thinking)
    try container.encodeIfPresent(tools, forKey: .tools)
    try container.encodeIfPresent(toolChoice, forKey: .toolChoice)
    try container.encodeIfPresent(outputConfig, forKey: .outputConfig)
    try container.encodeIfPresent(cacheControl, forKey: .cacheControl)
    try container.encodeIfPresent(serviceTier, forKey: .serviceTier)
    try container.encodeIfPresent(models, forKey: .models)
    try container.encodeIfPresent(provider, forKey: .provider)
    try container.encodeIfPresent(plugins, forKey: .plugins)
    try container.encodeIfPresent(sessionId, forKey: .sessionId)
    try container.encodeIfPresent(trace, forKey: .trace)
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
