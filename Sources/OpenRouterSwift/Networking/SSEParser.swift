import Foundation

/// Pure line-level SSE parsing for OpenRouter streams.
///
/// OpenRouter specifics handled here:
/// - Comment lines (`: OPENROUTER PROCESSING`) are keep-alives and must be skipped.
/// - `data: [DONE]` terminates the stream.
/// - `event:` lines are surfaced for typed streams (Responses API).
enum SSEParser {
  enum Line: Equatable {
    /// A `:` comment / keep-alive — ignore.
    case comment
    /// The `[DONE]` sentinel.
    case done
    /// A `data:` payload.
    case data(String)
    /// An `event:` name (Responses API typed events).
    case event(String)
    /// Blank line or anything else — ignore.
    case ignore
  }

  static func parse(line: String) -> Line {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty {
      return .ignore
    }
    if trimmed.hasPrefix(":") {
      return .comment
    }
    if trimmed.hasPrefix("event:") {
      return .event(String(trimmed.dropFirst("event:".count)).trimmingCharacters(in: .whitespaces))
    }
    if trimmed.hasPrefix("data:") {
      let payload = String(trimmed.dropFirst("data:".count)).trimmingCharacters(in: .whitespaces)
      if payload == "[DONE]" {
        return .done
      }
      return .data(payload)
    }
    return .ignore
  }
}
