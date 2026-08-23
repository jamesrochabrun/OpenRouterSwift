import Foundation

// MARK: - ResponseOutputItem

/// Items in the `output` array of a Responses result.
/// Unrecognized item types decode as `.other`.
public enum ResponseOutputItem: Decodable, Sendable {
  case message(id: String?, content: [MessageContent], status: String?)
  case reasoning(id: String?, summary: [String], content: [String], encryptedContent: String?)
  case functionCall(callId: String, name: String, arguments: String, id: String?, status: String?)
  case other(type: String, JSONValue)

  public enum MessageContent: Sendable {
    case outputText(String, annotations: [JSONValue]?)
    case refusal(String)
    case other(type: String, JSONValue)
  }

  private enum TypeKey: String, CodingKey {
    case type
  }

  private struct MessageItem: Decodable {
    let id: String?
    let content: [JSONValue]?
    let status: String?
  }

  private struct ReasoningItem: Decodable {
    let id: String?
    let summary: [JSONValue]?
    let content: [JSONValue]?
    let encryptedContent: String?

    enum CodingKeys: String, CodingKey {
      case id
      case summary
      case content
      case encryptedContent = "encrypted_content"
    }
  }

  private struct FunctionCallItem: Decodable {
    let callId: String
    let name: String
    let arguments: String
    let id: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
      case callId = "call_id"
      case name
      case arguments
      case id
      case status
    }
  }

  public init(from decoder: Decoder) throws {
    let typeContainer = try decoder.container(keyedBy: TypeKey.self)
    let type = try typeContainer.decode(String.self, forKey: .type)
    let single = try decoder.singleValueContainer()
    switch type {
    case "message":
      let item = try single.decode(MessageItem.self)
      let content = (item.content ?? []).map { value -> MessageContent in
        switch value["type"]?.stringValue {
        case "output_text":
          return .outputText(value["text"]?.stringValue ?? "", annotations: value["annotations"]?.arrayValue)
        case "refusal":
          return .refusal(value["refusal"]?.stringValue ?? "")
        default:
          return .other(type: value["type"]?.stringValue ?? "", value)
        }
      }
      self = .message(id: item.id, content: content, status: item.status)

    case "reasoning":
      let item = try single.decode(ReasoningItem.self)
      self = .reasoning(
        id: item.id,
        summary: (item.summary ?? []).compactMap { $0["text"]?.stringValue },
        content: (item.content ?? []).compactMap { $0["text"]?.stringValue },
        encryptedContent: item.encryptedContent)

    case "function_call":
      let item = try single.decode(FunctionCallItem.self)
      self = .functionCall(
        callId: item.callId,
        name: item.name,
        arguments: item.arguments,
        id: item.id,
        status: item.status)

    default:
      self = .other(type: type, try single.decode(JSONValue.self))
    }
  }
}

// MARK: - ResponsesUsage

public struct ResponsesUsage: Decodable, Sendable {
  public let inputTokens: Int?
  public let outputTokens: Int?
  public let totalTokens: Int?
  public let inputTokensDetails: InputTokensDetails?
  public let outputTokensDetails: OutputTokensDetails?
  /// USD cost (OpenRouter addition).
  public let cost: Double?
  public let isByok: Bool?
  public let costDetails: JSONValue?

  public struct InputTokensDetails: Decodable, Sendable {
    public let cachedTokens: Int?
    public let cacheWriteTokens: Int?

    enum CodingKeys: String, CodingKey {
      case cachedTokens = "cached_tokens"
      case cacheWriteTokens = "cache_write_tokens"
    }
  }

  public struct OutputTokensDetails: Decodable, Sendable {
    public let reasoningTokens: Int?

    enum CodingKeys: String, CodingKey {
      case reasoningTokens = "reasoning_tokens"
    }
  }

  enum CodingKeys: String, CodingKey {
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case totalTokens = "total_tokens"
    case inputTokensDetails = "input_tokens_details"
    case outputTokensDetails = "output_tokens_details"
    case cost
    case isByok = "is_byok"
    case costDetails = "cost_details"
  }
}

// MARK: - ResponsesResponse

/// Response from `POST /api/v1/responses` (non-streaming), and the payload of
/// `response.completed` / `response.failed` stream events.
public struct ResponsesResponse: Decodable, Sendable {
  public let id: String
  public let object: String?
  public let createdAt: Double?
  public let completedAt: Double?
  public let status: String?
  public let model: String?
  public let output: [ResponseOutputItem]
  /// Convenience concatenation of all output text, when provided by the API.
  public let outputText: String?
  public let error: ResponseError?
  public let incompleteDetails: JSONValue?
  public let usage: ResponsesUsage?
  public let openrouterMetadata: JSONValue?

  public struct ResponseError: Decodable, Sendable {
    public let code: String?
    public let message: String?
  }

  /// All output text, from `outputText` or assembled from message items.
  public var text: String {
    if let outputText { return outputText }
    return output.compactMap { item -> String? in
      guard case .message(_, let content, _) = item else { return nil }
      return content.compactMap { part -> String? in
        guard case .outputText(let text, _) = part else { return nil }
        return text
      }.joined()
    }.joined()
  }

  enum CodingKeys: String, CodingKey {
    case id
    case object
    case createdAt = "created_at"
    case completedAt = "completed_at"
    case status
    case model
    case output
    case outputText = "output_text"
    case error
    case incompleteDetails = "incomplete_details"
    case usage
    case openrouterMetadata = "openrouter_metadata"
  }
}

// MARK: - ResponsesStreamEvent

/// SSE events from `POST /api/v1/responses` with `stream: true`.
/// The most useful events are typed; everything else lands in `.other` with its full payload.
public enum ResponsesStreamEvent: Decodable, Sendable {
  case created(ResponsesResponse)
  case inProgress(ResponsesResponse)
  case outputItemAdded(outputIndex: Int, item: ResponseOutputItem)
  case outputItemDone(outputIndex: Int, item: ResponseOutputItem)
  case outputTextDelta(itemId: String?, outputIndex: Int?, delta: String)
  case outputTextDone(itemId: String?, outputIndex: Int?, text: String)
  case reasoningTextDelta(itemId: String?, outputIndex: Int?, delta: String)
  case functionCallArgumentsDelta(itemId: String?, outputIndex: Int?, delta: String)
  case functionCallArgumentsDone(itemId: String?, outputIndex: Int?, arguments: String)
  case refusalDelta(itemId: String?, delta: String)
  case completed(ResponsesResponse)
  case failed(ResponsesResponse)
  case incomplete(ResponsesResponse)
  case error(code: String?, message: String?)
  case other(type: String, JSONValue)

  private enum TypeKey: String, CodingKey {
    case type
  }

  private struct ResponseEvent: Decodable {
    let response: ResponsesResponse
  }

  private struct ItemEvent: Decodable {
    let outputIndex: Int
    let item: ResponseOutputItem

    enum CodingKeys: String, CodingKey {
      case outputIndex = "output_index"
      case item
    }
  }

  private struct DeltaEvent: Decodable {
    let itemId: String?
    let outputIndex: Int?
    let delta: String?
    let text: String?
    let arguments: String?

    enum CodingKeys: String, CodingKey {
      case itemId = "item_id"
      case outputIndex = "output_index"
      case delta
      case text
      case arguments
    }
  }

  private struct ErrorEvent: Decodable {
    let code: String?
    let message: String?
  }

  public init(from decoder: Decoder) throws {
    let typeContainer = try decoder.container(keyedBy: TypeKey.self)
    let type = try typeContainer.decode(String.self, forKey: .type)
    let single = try decoder.singleValueContainer()
    switch type {
    case "response.created":
      self = .created(try single.decode(ResponseEvent.self).response)

    case "response.in_progress":
      self = .inProgress(try single.decode(ResponseEvent.self).response)

    case "response.output_item.added":
      let event = try single.decode(ItemEvent.self)
      self = .outputItemAdded(outputIndex: event.outputIndex, item: event.item)

    case "response.output_item.done":
      let event = try single.decode(ItemEvent.self)
      self = .outputItemDone(outputIndex: event.outputIndex, item: event.item)

    case "response.output_text.delta":
      let event = try single.decode(DeltaEvent.self)
      self = .outputTextDelta(itemId: event.itemId, outputIndex: event.outputIndex, delta: event.delta ?? "")

    case "response.output_text.done":
      let event = try single.decode(DeltaEvent.self)
      self = .outputTextDone(itemId: event.itemId, outputIndex: event.outputIndex, text: event.text ?? "")

    case "response.reasoning_text.delta":
      let event = try single.decode(DeltaEvent.self)
      self = .reasoningTextDelta(itemId: event.itemId, outputIndex: event.outputIndex, delta: event.delta ?? "")

    case "response.function_call_arguments.delta":
      let event = try single.decode(DeltaEvent.self)
      self = .functionCallArgumentsDelta(itemId: event.itemId, outputIndex: event.outputIndex, delta: event.delta ?? "")

    case "response.function_call_arguments.done":
      let event = try single.decode(DeltaEvent.self)
      self = .functionCallArgumentsDone(itemId: event.itemId, outputIndex: event.outputIndex, arguments: event.arguments ?? "")

    case "response.refusal.delta":
      let event = try single.decode(DeltaEvent.self)
      self = .refusalDelta(itemId: event.itemId, delta: event.delta ?? "")

    case "response.completed":
      self = .completed(try single.decode(ResponseEvent.self).response)

    case "response.failed":
      self = .failed(try single.decode(ResponseEvent.self).response)

    case "response.incomplete":
      self = .incomplete(try single.decode(ResponseEvent.self).response)

    case "error":
      let event = try single.decode(ErrorEvent.self)
      self = .error(code: event.code, message: event.message)

    default:
      self = .other(type: type, try single.decode(JSONValue.self))
    }
  }
}
