import Foundation

// MARK: - OpenRouterAPIErrorBody

/// The structured error body OpenRouter returns: `{"error": {"code": ..., "message": ..., "metadata": ...}}`.
public struct OpenRouterAPIErrorBody: Decodable, Sendable {
  public let code: Int?
  public let message: String
  public let metadata: [String: JSONValue]?
}

struct OpenRouterErrorEnvelope: Decodable {
  let error: OpenRouterAPIErrorBody
}

// MARK: - OpenRouterError

/// Errors thrown by OpenRouterSwift, mapping OpenRouter's documented HTTP semantics:
/// 402 insufficient credits, 403 guardrail/moderation, 429 rate limited,
/// 524 edge timeout, 529 provider overloaded, plus mid-stream error events
/// that arrive as SSE data under HTTP 200.
public enum OpenRouterError: Error {
  /// Any non-2xx response not covered by a dedicated case.
  case api(statusCode: Int, message: String, metadata: [String: JSONValue]?)
  /// 402 — the account or key has insufficient credits.
  case insufficientCredits(message: String)
  /// 403 — input or output was blocked by a guardrail / moderation policy.
  case guardrailViolation(message: String, metadata: [String: JSONValue]?)
  /// 429 — rate limited. `retryAfter` is parsed from the `Retry-After` header when present.
  case rateLimited(message: String, retryAfter: TimeInterval?)
  /// 524 — the edge timed out waiting for the provider.
  case providerTimeout(message: String)
  /// 529 — the routed provider is overloaded.
  case serviceOverloaded(message: String)
  /// An error event delivered mid-stream over SSE (HTTP status was 200).
  case streamError(code: Int?, message: String, metadata: [String: JSONValue]?)
  /// The response body could not be decoded into the expected type.
  case decodingFailure(description: String, raw: Data)
  /// A transport-level failure (connection, cancellation bridging, etc.).
  case transport(any Error)
  /// The response was structurally invalid (e.g. no byte stream for a streaming call).
  case invalidResponse(description: String)
}

// MARK: LocalizedError

extension OpenRouterError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .api(let statusCode, let message, _):
      return "OpenRouter API error (\(statusCode)): \(message)"
    case .insufficientCredits(let message):
      return "Insufficient credits: \(message)"
    case .guardrailViolation(let message, _):
      return "Guardrail violation: \(message)"
    case .rateLimited(let message, let retryAfter):
      let suffix = retryAfter.map { " Retry after \($0)s." } ?? ""
      return "Rate limited: \(message)\(suffix)"
    case .providerTimeout(let message):
      return "Provider timeout: \(message)"
    case .serviceOverloaded(let message):
      return "Provider overloaded: \(message)"
    case .streamError(let code, let message, _):
      let codeText = code.map { " (\($0))" } ?? ""
      return "Stream error\(codeText): \(message)"
    case .decodingFailure(let description, _):
      return "Decoding failure: \(description)"
    case .transport(let error):
      return "Transport error: \(error)"
    case .invalidResponse(let description):
      return "Invalid response: \(description)"
    }
  }
}
