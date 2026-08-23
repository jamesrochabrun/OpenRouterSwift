import Foundation

// MARK: - ChatCompletionResponse

/// Response from `POST /api/v1/chat/completions` (non-streaming).
public struct ChatCompletionResponse: Decodable, Sendable {
  /// Generation id — use with `generation(id:)` for post-hoc cost/latency stats.
  public let id: String
  /// The provider the request was actually routed to.
  public let provider: String?
  /// The model that actually served the request (post-routing).
  public let model: String
  public let object: String?
  public let created: Int?
  public let choices: [Choice]
  public let usage: Usage?
  public let systemFingerprint: String?
  /// Routing metadata, present when the `X-OpenRouter-Metadata: enabled` header is sent.
  public let openrouterMetadata: JSONValue?

  public struct Choice: Decodable, Sendable {
    public let index: Int?
    public let message: ResponseMessage
    public let finishReason: String?
    /// The provider's raw finish reason, before normalization.
    public let nativeFinishReason: String?
    public let logprobs: JSONValue?

    enum CodingKeys: String, CodingKey {
      case index
      case message
      case finishReason = "finish_reason"
      case nativeFinishReason = "native_finish_reason"
      case logprobs
    }
  }

  public struct ResponseMessage: Decodable, Sendable {
    public let role: String?
    public let content: String?
    /// Reasoning text, when the model emits it.
    public let reasoning: String?
    /// Structured reasoning blocks (summaries, encrypted blocks, raw text).
    public let reasoningDetails: [JSONValue]?
    public let toolCalls: [ToolCall]?
    public let refusal: String?
    /// Generated images (data URIs) for image-output models.
    public let images: [JSONValue]?
    /// Annotations, e.g. URL citations from web search.
    public let annotations: [JSONValue]?

    enum CodingKeys: String, CodingKey {
      case role
      case content
      case reasoning
      case reasoningDetails = "reasoning_details"
      case toolCalls = "tool_calls"
      case refusal
      case images
      case annotations
    }
  }

  enum CodingKeys: String, CodingKey {
    case id
    case provider
    case model
    case object
    case created
    case choices
    case usage
    case systemFingerprint = "system_fingerprint"
    case openrouterMetadata = "openrouter_metadata"
  }
}

// MARK: - ChatCompletionChunk

/// A streamed chunk from `POST /api/v1/chat/completions` with `stream: true`.
/// The final chunk carries `usage`.
public struct ChatCompletionChunk: Decodable, Sendable {
  public let id: String?
  public let provider: String?
  public let model: String?
  public let object: String?
  public let created: Int?
  public let choices: [StreamChoice]?
  public let usage: Usage?
  public let openrouterMetadata: JSONValue?

  public struct StreamChoice: Decodable, Sendable {
    public let index: Int?
    public let delta: Delta?
    public let finishReason: String?
    public let nativeFinishReason: String?

    enum CodingKeys: String, CodingKey {
      case index
      case delta
      case finishReason = "finish_reason"
      case nativeFinishReason = "native_finish_reason"
    }
  }

  public struct Delta: Decodable, Sendable {
    public let role: String?
    public let content: String?
    public let reasoning: String?
    public let reasoningDetails: [JSONValue]?
    public let toolCalls: [ToolCall]?
    public let refusal: String?
    public let images: [JSONValue]?

    enum CodingKeys: String, CodingKey {
      case role
      case content
      case reasoning
      case reasoningDetails = "reasoning_details"
      case toolCalls = "tool_calls"
      case refusal
      case images
    }
  }

  enum CodingKeys: String, CodingKey {
    case id
    case provider
    case model
    case object
    case created
    case choices
    case usage
    case openrouterMetadata = "openrouter_metadata"
  }
}
