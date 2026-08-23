import Foundation

// MARK: - CacheControl

/// Anthropic-style prompt-cache breakpoint, attachable to individual content parts.
public struct CacheControl: Codable, Equatable, Sendable {
  public var type: String
  /// Optional TTL, e.g. `"5m"` or `"1h"` where supported.
  public var ttl: String?

  public init(type: String = "ephemeral", ttl: String? = nil) {
    self.type = type
    self.ttl = ttl
  }

  public static let ephemeral = CacheControl()
}

// MARK: - Message

/// A chat message in OpenRouter's `/chat/completions` format.
public struct Message: Encodable, Sendable {
  public enum Role: String, Codable, Sendable {
    case system
    case developer
    case user
    case assistant
    case tool
  }

  public enum Content: Encodable, Sendable {
    case text(String)
    case parts([ContentPart])

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .text(let text): try container.encode(text)
      case .parts(let parts): try container.encode(parts)
      }
    }
  }

  public var role: Role
  public var content: Content?
  /// Participant name, when disambiguating multiple users/assistants.
  public var name: String?
  /// For `role: .tool` — the id of the tool call this message responds to.
  public var toolCallId: String?
  /// For `role: .assistant` — tool calls previously made by the assistant.
  public var toolCalls: [ToolCall]?
  /// Message-level cache breakpoint (in addition to part-level `cacheControl`).
  public var cacheControl: CacheControl?

  public init(
    role: Role,
    content: Content? = nil,
    name: String? = nil,
    toolCallId: String? = nil,
    toolCalls: [ToolCall]? = nil,
    cacheControl: CacheControl? = nil)
  {
    self.role = role
    self.content = content
    self.name = name
    self.toolCallId = toolCallId
    self.toolCalls = toolCalls
    self.cacheControl = cacheControl
  }

  /// Convenience for plain-text messages: `.user("Hello")`.
  public static func system(_ text: String) -> Message { Message(role: .system, content: .text(text)) }
  public static func user(_ text: String) -> Message { Message(role: .user, content: .text(text)) }
  public static func assistant(_ text: String) -> Message { Message(role: .assistant, content: .text(text)) }
  public static func tool(_ text: String, toolCallId: String) -> Message {
    Message(role: .tool, content: .text(text), toolCallId: toolCallId)
  }

  enum CodingKeys: String, CodingKey {
    case role
    case content
    case name
    case toolCallId = "tool_call_id"
    case toolCalls = "tool_calls"
    case cacheControl = "cache_control"
  }
}

// MARK: - ContentPart

/// Multimodal content parts: text, image, audio, and file (PDF) inputs.
public enum ContentPart: Encodable, Sendable {
  case text(String, cacheControl: CacheControl? = nil)
  /// `url` accepts an https URL or a `data:` URI (base64).
  case imageURL(url: String, detail: String? = nil, cacheControl: CacheControl? = nil)
  /// Base64-encoded audio. `format` e.g. `"wav"`, `"mp3"`.
  case inputAudio(data: String, format: String, cacheControl: CacheControl? = nil)
  /// File input (e.g. PDF, parsed via the `file-parser` plugin). `fileData` is a data URI or URL.
  case file(filename: String, fileData: String, cacheControl: CacheControl? = nil)

  enum CodingKeys: String, CodingKey {
    case type
    case text
    case imageURL = "image_url"
    case inputAudio = "input_audio"
    case file
    case cacheControl = "cache_control"
  }

  struct ImageURL: Encodable {
    let url: String
    let detail: String?
  }

  struct InputAudio: Encodable {
    let data: String
    let format: String
  }

  struct File: Encodable {
    let filename: String
    let fileData: String

    enum CodingKeys: String, CodingKey {
      case filename
      case fileData = "file_data"
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .text(let text, let cacheControl):
      try container.encode("text", forKey: .type)
      try container.encode(text, forKey: .text)
      try container.encodeIfPresent(cacheControl, forKey: .cacheControl)

    case .imageURL(let url, let detail, let cacheControl):
      try container.encode("image_url", forKey: .type)
      try container.encode(ImageURL(url: url, detail: detail), forKey: .imageURL)
      try container.encodeIfPresent(cacheControl, forKey: .cacheControl)

    case .inputAudio(let data, let format, let cacheControl):
      try container.encode("input_audio", forKey: .type)
      try container.encode(InputAudio(data: data, format: format), forKey: .inputAudio)
      try container.encodeIfPresent(cacheControl, forKey: .cacheControl)

    case .file(let filename, let fileData, let cacheControl):
      try container.encode("file", forKey: .type)
      try container.encode(File(filename: filename, fileData: fileData), forKey: .file)
      try container.encodeIfPresent(cacheControl, forKey: .cacheControl)
    }
  }
}
