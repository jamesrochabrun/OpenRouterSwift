import Foundation

// MARK: - AnthropicResponseContentBlock

/// Output content blocks from `/messages`. Unrecognized block types decode as `.other`.
public enum AnthropicResponseContentBlock: Decodable, Sendable {
  case text(String)
  case toolUse(id: String, name: String, input: JSONValue)
  case thinking(String, signature: String?)
  case redactedThinking(data: String)
  case other(type: String, JSONValue)

  private enum TypeKey: String, CodingKey {
    case type
  }

  private struct TextBlock: Decodable {
    let text: String
  }

  private struct ToolUseBlock: Decodable {
    let id: String
    let name: String
    let input: JSONValue?
  }

  private struct ThinkingBlock: Decodable {
    let thinking: String
    let signature: String?
  }

  private struct RedactedBlock: Decodable {
    let data: String
  }

  public init(from decoder: Decoder) throws {
    let typeContainer = try decoder.container(keyedBy: TypeKey.self)
    let type = try typeContainer.decode(String.self, forKey: .type)
    let single = try decoder.singleValueContainer()
    switch type {
    case "text":
      self = .text(try single.decode(TextBlock.self).text)
    case "tool_use":
      let block = try single.decode(ToolUseBlock.self)
      self = .toolUse(id: block.id, name: block.name, input: block.input ?? .null)
    case "thinking":
      let block = try single.decode(ThinkingBlock.self)
      self = .thinking(block.thinking, signature: block.signature)
    case "redacted_thinking":
      self = .redactedThinking(data: try single.decode(RedactedBlock.self).data)
    default:
      self = .other(type: type, try single.decode(JSONValue.self))
    }
  }

  /// The block's text, when it is a text block.
  public var textValue: String? {
    if case .text(let text) = self { return text }
    return nil
  }
}

// MARK: - AnthropicUsage

/// Usage for `/messages` responses (Anthropic naming + OpenRouter cost accounting).
public struct AnthropicUsage: Decodable, Sendable {
  public let inputTokens: Int?
  public let outputTokens: Int?
  public let cacheCreationInputTokens: Int?
  public let cacheReadInputTokens: Int?
  /// USD cost (OpenRouter addition).
  public let cost: Double?
  public let isByok: Bool?
  public let costDetails: JSONValue?
  public let outputTokensDetails: OutputTokensDetails?

  public struct OutputTokensDetails: Decodable, Sendable {
    public let thinkingTokens: Int?

    enum CodingKeys: String, CodingKey {
      case thinkingTokens = "thinking_tokens"
    }
  }

  enum CodingKeys: String, CodingKey {
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case cacheCreationInputTokens = "cache_creation_input_tokens"
    case cacheReadInputTokens = "cache_read_input_tokens"
    case cost
    case isByok = "is_byok"
    case costDetails = "cost_details"
    case outputTokensDetails = "output_tokens_details"
  }
}

// MARK: - MessagesResponse

/// Response from `POST /api/v1/messages` (non-streaming).
public struct MessagesResponse: Decodable, Sendable {
  public let id: String
  public let type: String?
  public let model: String
  public let role: String?
  public let content: [AnthropicResponseContentBlock]
  public let stopReason: String?
  public let stopSequence: String?
  public let usage: AnthropicUsage?
  /// The provider the request was routed to (OpenRouter addition).
  public let provider: String?
  public let openrouterMetadata: JSONValue?

  /// Concatenated text of all text blocks.
  public var text: String {
    content.compactMap(\.textValue).joined()
  }

  enum CodingKeys: String, CodingKey {
    case id
    case type
    case model
    case role
    case content
    case stopReason = "stop_reason"
    case stopSequence = "stop_sequence"
    case usage
    case provider
    case openrouterMetadata = "openrouter_metadata"
  }
}

// MARK: - MessagesStreamEvent

/// SSE events from `POST /api/v1/messages` with `stream: true`.
/// Unrecognized event types decode as `.other`.
public enum MessagesStreamEvent: Decodable, Sendable {
  case messageStart(JSONValue)
  case contentBlockStart(index: Int, contentBlock: JSONValue)
  case contentBlockDelta(index: Int, delta: Delta)
  case contentBlockStop(index: Int)
  /// Carries `stop_reason` and cumulative output usage.
  case messageDelta(delta: JSONValue, usage: JSONValue?)
  case messageStop
  case ping
  case other(type: String, JSONValue)

  public enum Delta: Sendable {
    case textDelta(String)
    case inputJSONDelta(partialJSON: String)
    case thinkingDelta(String)
    case signatureDelta(String)
    case other(type: String, JSONValue)
  }

  private enum TypeKey: String, CodingKey {
    case type
  }

  private struct BlockEvent: Decodable {
    let index: Int
    let contentBlock: JSONValue?
    let delta: JSONValue?

    enum CodingKeys: String, CodingKey {
      case index
      case contentBlock = "content_block"
      case delta
    }
  }

  private struct MessageDeltaEvent: Decodable {
    let delta: JSONValue
    let usage: JSONValue?
  }

  private struct MessageStartEvent: Decodable {
    let message: JSONValue
  }

  public init(from decoder: Decoder) throws {
    let typeContainer = try decoder.container(keyedBy: TypeKey.self)
    let type = try typeContainer.decode(String.self, forKey: .type)
    let single = try decoder.singleValueContainer()
    switch type {
    case "message_start":
      self = .messageStart(try single.decode(MessageStartEvent.self).message)

    case "content_block_start":
      let event = try single.decode(BlockEvent.self)
      self = .contentBlockStart(index: event.index, contentBlock: event.contentBlock ?? .null)

    case "content_block_delta":
      let event = try single.decode(BlockEvent.self)
      self = .contentBlockDelta(index: event.index, delta: Self.parseDelta(event.delta ?? .null))

    case "content_block_stop":
      let event = try single.decode(BlockEvent.self)
      self = .contentBlockStop(index: event.index)

    case "message_delta":
      let event = try single.decode(MessageDeltaEvent.self)
      self = .messageDelta(delta: event.delta, usage: event.usage)

    case "message_stop":
      self = .messageStop

    case "ping":
      self = .ping

    default:
      self = .other(type: type, try single.decode(JSONValue.self))
    }
  }

  private static func parseDelta(_ value: JSONValue) -> Delta {
    let type = value["type"]?.stringValue ?? ""
    switch type {
    case "text_delta":
      return .textDelta(value["text"]?.stringValue ?? "")
    case "input_json_delta":
      return .inputJSONDelta(partialJSON: value["partial_json"]?.stringValue ?? "")
    case "thinking_delta":
      return .thinkingDelta(value["thinking"]?.stringValue ?? "")
    case "signature_delta":
      return .signatureDelta(value["signature"]?.stringValue ?? "")
    default:
      return .other(type: type, value)
    }
  }
}
