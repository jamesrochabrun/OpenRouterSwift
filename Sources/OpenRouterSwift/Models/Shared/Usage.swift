import Foundation

/// Token usage and cost accounting. OpenRouter always returns usage (including USD `cost`)
/// on completions; on streams it arrives on the final chunk.
public struct Usage: Decodable, Sendable {
  public let promptTokens: Int?
  public let completionTokens: Int?
  public let totalTokens: Int?
  /// Total cost in USD credits. `0` for BYOK requests (see `costDetails.upstreamInferenceCost`).
  public let cost: Double?
  public let isByok: Bool?
  public let costDetails: CostDetails?
  public let promptTokensDetails: PromptTokensDetails?
  public let completionTokensDetails: CompletionTokensDetails?

  public struct CostDetails: Decodable, Sendable {
    public let upstreamInferenceCost: Double?
    public let upstreamInferencePromptCost: Double?
    public let upstreamInferenceCompletionsCost: Double?

    enum CodingKeys: String, CodingKey {
      case upstreamInferenceCost = "upstream_inference_cost"
      case upstreamInferencePromptCost = "upstream_inference_prompt_cost"
      case upstreamInferenceCompletionsCost = "upstream_inference_completions_cost"
    }
  }

  public struct PromptTokensDetails: Decodable, Sendable {
    public let cachedTokens: Int?
    public let cacheWriteTokens: Int?
    public let audioTokens: Int?

    enum CodingKeys: String, CodingKey {
      case cachedTokens = "cached_tokens"
      case cacheWriteTokens = "cache_write_tokens"
      case audioTokens = "audio_tokens"
    }
  }

  public struct CompletionTokensDetails: Decodable, Sendable {
    public let reasoningTokens: Int?
    public let audioTokens: Int?

    enum CodingKeys: String, CodingKey {
      case reasoningTokens = "reasoning_tokens"
      case audioTokens = "audio_tokens"
    }
  }

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
    case cost
    case isByok = "is_byok"
    case costDetails = "cost_details"
    case promptTokensDetails = "prompt_tokens_details"
    case completionTokensDetails = "completion_tokens_details"
  }
}
