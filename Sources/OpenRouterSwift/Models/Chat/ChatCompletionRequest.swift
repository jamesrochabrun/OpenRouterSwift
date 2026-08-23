import Foundation

// MARK: - Supporting types

/// Predicted output for latency optimization.
public struct Prediction: Encodable, Sendable {
  public var type: String
  public var content: String

  public init(content: String) {
    type = "content"
    self.content = content
  }
}

public struct StreamOptions: Encodable, Sendable {
  /// Deprecated no-op on OpenRouter (usage is always included); kept for OpenAI compatibility.
  public var includeUsage: Bool?

  public init(includeUsage: Bool? = nil) {
    self.includeUsage = includeUsage
  }

  enum CodingKeys: String, CodingKey {
    case includeUsage = "include_usage"
  }
}

/// Distributed-tracing metadata (`trace` request field).
public struct Trace: Encodable, Sendable {
  public var traceId: String?
  public var spanName: String?
  public var parentSpanId: String?

  public init(traceId: String? = nil, spanName: String? = nil, parentSpanId: String? = nil) {
    self.traceId = traceId
    self.spanName = spanName
    self.parentSpanId = parentSpanId
  }

  enum CodingKeys: String, CodingKey {
    case traceId = "trace_id"
    case spanName = "span_name"
    case parentSpanId = "parent_span_id"
  }
}

// MARK: - ChatCompletionRequest

/// Request body for `POST /api/v1/chat/completions`, matching OpenRouter's schema.
///
/// Any parameter this type doesn't model yet can be passed through `extraBody`,
/// which is deep-merged into the encoded JSON at the top level.
public struct ChatCompletionRequest: Encodable, Sendable {
  // Core
  public var model: String?
  /// Fallback models, tried in order if `model` fails.
  public var models: [String]?
  public var messages: [Message]

  // OpenRouter routing & features
  public var provider: ProviderPreferences?
  public var plugins: [Plugin]?
  public var reasoning: Reasoning?
  /// Shorthand for `reasoning.effort`.
  public var reasoningEffort: Reasoning.Effort?
  public var responseFormat: ResponseFormat?
  /// Sticky-session routing key (max 256 chars).
  public var sessionId: String?
  public var trace: Trace?
  /// Halt server-side agent loops (step_count, max_cost, token limits...). Free-form until the shape stabilizes.
  public var stopServerToolsWhen: JSONValue?
  /// Provider-specific image-output options for image-generating chat models.
  public var imageConfig: JSONValue?
  /// Request-level cache breakpoint.
  public var cacheControl: CacheControl?
  public var promptCacheKey: String?
  public var promptCacheOptions: JSONValue?

  // Tools
  public var tools: [Tool]?
  public var toolChoice: ToolChoice?
  public var parallelToolCalls: Bool?

  // Sampling
  public var temperature: Double?
  public var topP: Double?
  public var topK: Int?
  public var minP: Double?
  public var topA: Double?
  public var frequencyPenalty: Double?
  public var presencePenalty: Double?
  public var repetitionPenalty: Double?
  public var logitBias: [String: Double]?
  public var logprobs: Bool?
  public var topLogprobs: Int?
  public var seed: Int?
  public var maxTokens: Int?
  public var maxCompletionTokens: Int?
  public var stop: [String]?
  public var prediction: Prediction?

  // Output
  public var modalities: [String]?
  public var verbosity: String?
  public var serviceTier: String?

  // Streaming
  public var stream: Bool?
  public var streamOptions: StreamOptions?

  // Misc
  public var user: String?
  public var metadata: [String: String]?
  /// Streaming-only diagnostics, e.g. `{"echo_upstream_body": true}`.
  public var debug: JSONValue?

  /// Escape hatch: keys merged into the top-level JSON at encode time.
  /// Existing typed fields win on key collisions.
  public var extraBody: [String: JSONValue]?

  public init(
    model: String? = nil,
    models: [String]? = nil,
    messages: [Message],
    provider: ProviderPreferences? = nil,
    plugins: [Plugin]? = nil,
    reasoning: Reasoning? = nil,
    reasoningEffort: Reasoning.Effort? = nil,
    responseFormat: ResponseFormat? = nil,
    sessionId: String? = nil,
    trace: Trace? = nil,
    stopServerToolsWhen: JSONValue? = nil,
    imageConfig: JSONValue? = nil,
    cacheControl: CacheControl? = nil,
    promptCacheKey: String? = nil,
    promptCacheOptions: JSONValue? = nil,
    tools: [Tool]? = nil,
    toolChoice: ToolChoice? = nil,
    parallelToolCalls: Bool? = nil,
    temperature: Double? = nil,
    topP: Double? = nil,
    topK: Int? = nil,
    minP: Double? = nil,
    topA: Double? = nil,
    frequencyPenalty: Double? = nil,
    presencePenalty: Double? = nil,
    repetitionPenalty: Double? = nil,
    logitBias: [String: Double]? = nil,
    logprobs: Bool? = nil,
    topLogprobs: Int? = nil,
    seed: Int? = nil,
    maxTokens: Int? = nil,
    maxCompletionTokens: Int? = nil,
    stop: [String]? = nil,
    prediction: Prediction? = nil,
    modalities: [String]? = nil,
    verbosity: String? = nil,
    serviceTier: String? = nil,
    stream: Bool? = nil,
    streamOptions: StreamOptions? = nil,
    user: String? = nil,
    metadata: [String: String]? = nil,
    debug: JSONValue? = nil,
    extraBody: [String: JSONValue]? = nil)
  {
    self.model = model
    self.models = models
    self.messages = messages
    self.provider = provider
    self.plugins = plugins
    self.reasoning = reasoning
    self.reasoningEffort = reasoningEffort
    self.responseFormat = responseFormat
    self.sessionId = sessionId
    self.trace = trace
    self.stopServerToolsWhen = stopServerToolsWhen
    self.imageConfig = imageConfig
    self.cacheControl = cacheControl
    self.promptCacheKey = promptCacheKey
    self.promptCacheOptions = promptCacheOptions
    self.tools = tools
    self.toolChoice = toolChoice
    self.parallelToolCalls = parallelToolCalls
    self.temperature = temperature
    self.topP = topP
    self.topK = topK
    self.minP = minP
    self.topA = topA
    self.frequencyPenalty = frequencyPenalty
    self.presencePenalty = presencePenalty
    self.repetitionPenalty = repetitionPenalty
    self.logitBias = logitBias
    self.logprobs = logprobs
    self.topLogprobs = topLogprobs
    self.seed = seed
    self.maxTokens = maxTokens
    self.maxCompletionTokens = maxCompletionTokens
    self.stop = stop
    self.prediction = prediction
    self.modalities = modalities
    self.verbosity = verbosity
    self.serviceTier = serviceTier
    self.stream = stream
    self.streamOptions = streamOptions
    self.user = user
    self.metadata = metadata
    self.debug = debug
    self.extraBody = extraBody
  }

  enum CodingKeys: String, CodingKey {
    case model
    case models
    case messages
    case provider
    case plugins
    case reasoning
    case reasoningEffort = "reasoning_effort"
    case responseFormat = "response_format"
    case sessionId = "session_id"
    case trace
    case stopServerToolsWhen = "stop_server_tools_when"
    case imageConfig = "image_config"
    case cacheControl = "cache_control"
    case promptCacheKey = "prompt_cache_key"
    case promptCacheOptions = "prompt_cache_options"
    case tools
    case toolChoice = "tool_choice"
    case parallelToolCalls = "parallel_tool_calls"
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case minP = "min_p"
    case topA = "top_a"
    case frequencyPenalty = "frequency_penalty"
    case presencePenalty = "presence_penalty"
    case repetitionPenalty = "repetition_penalty"
    case logitBias = "logit_bias"
    case logprobs
    case topLogprobs = "top_logprobs"
    case seed
    case maxTokens = "max_tokens"
    case maxCompletionTokens = "max_completion_tokens"
    case stop
    case prediction
    case modalities
    case verbosity
    case serviceTier = "service_tier"
    case stream
    case streamOptions = "stream_options"
    case user
    case metadata
    case debug
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
    try container.encode(messages, forKey: .messages)
    try container.encodeIfPresent(provider, forKey: .provider)
    try container.encodeIfPresent(plugins, forKey: .plugins)
    try container.encodeIfPresent(reasoning, forKey: .reasoning)
    try container.encodeIfPresent(reasoningEffort, forKey: .reasoningEffort)
    try container.encodeIfPresent(responseFormat, forKey: .responseFormat)
    try container.encodeIfPresent(sessionId, forKey: .sessionId)
    try container.encodeIfPresent(trace, forKey: .trace)
    try container.encodeIfPresent(stopServerToolsWhen, forKey: .stopServerToolsWhen)
    try container.encodeIfPresent(imageConfig, forKey: .imageConfig)
    try container.encodeIfPresent(cacheControl, forKey: .cacheControl)
    try container.encodeIfPresent(promptCacheKey, forKey: .promptCacheKey)
    try container.encodeIfPresent(promptCacheOptions, forKey: .promptCacheOptions)
    try container.encodeIfPresent(tools, forKey: .tools)
    try container.encodeIfPresent(toolChoice, forKey: .toolChoice)
    try container.encodeIfPresent(parallelToolCalls, forKey: .parallelToolCalls)
    try container.encodeIfPresent(temperature, forKey: .temperature)
    try container.encodeIfPresent(topP, forKey: .topP)
    try container.encodeIfPresent(topK, forKey: .topK)
    try container.encodeIfPresent(minP, forKey: .minP)
    try container.encodeIfPresent(topA, forKey: .topA)
    try container.encodeIfPresent(frequencyPenalty, forKey: .frequencyPenalty)
    try container.encodeIfPresent(presencePenalty, forKey: .presencePenalty)
    try container.encodeIfPresent(repetitionPenalty, forKey: .repetitionPenalty)
    try container.encodeIfPresent(logitBias, forKey: .logitBias)
    try container.encodeIfPresent(logprobs, forKey: .logprobs)
    try container.encodeIfPresent(topLogprobs, forKey: .topLogprobs)
    try container.encodeIfPresent(seed, forKey: .seed)
    try container.encodeIfPresent(maxTokens, forKey: .maxTokens)
    try container.encodeIfPresent(maxCompletionTokens, forKey: .maxCompletionTokens)
    try container.encodeIfPresent(stop, forKey: .stop)
    try container.encodeIfPresent(prediction, forKey: .prediction)
    try container.encodeIfPresent(modalities, forKey: .modalities)
    try container.encodeIfPresent(verbosity, forKey: .verbosity)
    try container.encodeIfPresent(serviceTier, forKey: .serviceTier)
    try container.encodeIfPresent(stream, forKey: .stream)
    try container.encodeIfPresent(streamOptions, forKey: .streamOptions)
    try container.encodeIfPresent(user, forKey: .user)
    try container.encodeIfPresent(metadata, forKey: .metadata)
    try container.encodeIfPresent(debug, forKey: .debug)

    if let extraBody {
      let typedKeys = CodingKeys.allKeys
      var dynamic = encoder.container(keyedBy: DynamicKey.self)
      for (key, value) in extraBody where !typedKeys.contains(key) {
        try dynamic.encode(value, forKey: DynamicKey(stringValue: key))
      }
    }
  }
}

extension ChatCompletionRequest.CodingKeys {
  static var allKeys: Set<String> {
    Set(ChatCompletionRequest.CodingKeys.allCases.map(\.rawValue))
  }
}

extension ChatCompletionRequest.CodingKeys: CaseIterable { }
