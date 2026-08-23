import Foundation

/// Result of `GET /api/v1/generation?id=` — authoritative post-hoc stats for one generation:
/// exact cost, native (provider-tokenizer) token counts, latency, and routing details.
public struct Generation: Decodable, Sendable {
  public let id: String
  public let model: String?
  public let providerName: String?
  public let created: Double?
  public let streamed: Bool?
  public let cancelled: Bool?
  public let isByok: Bool?

  // Cost
  public let totalCost: Double?
  public let cacheDiscount: Double?
  public let upstreamInferenceCost: Double?

  // Normalized (GPT-tokenizer) counts
  public let tokensPrompt: Int?
  public let tokensCompletion: Int?

  // Native provider-tokenizer counts — use these for billing math
  public let nativeTokensPrompt: Int?
  public let nativeTokensCompletion: Int?
  public let nativeTokensReasoning: Int?
  public let nativeTokensCached: Int?

  // Timing
  public let latency: Int?
  public let generationTime: Int?
  public let moderationLatency: Int?

  // Outcome
  public let finishReason: String?
  public let nativeFinishReason: String?

  // Context
  public let appId: Int?
  public let sessionId: String?
  public let workspaceId: String?
  public let router: String?
  public let numMediaPrompt: Int?
  public let numMediaCompletion: Int?
  public let numSearchResults: Int?
  public let webSearchEngine: String?

  enum CodingKeys: String, CodingKey {
    case id
    case model
    case providerName = "provider_name"
    case created = "created_at"
    case streamed
    case cancelled
    case isByok = "is_byok"
    case totalCost = "total_cost"
    case cacheDiscount = "cache_discount"
    case upstreamInferenceCost = "upstream_inference_cost"
    case tokensPrompt = "tokens_prompt"
    case tokensCompletion = "tokens_completion"
    case nativeTokensPrompt = "native_tokens_prompt"
    case nativeTokensCompletion = "native_tokens_completion"
    case nativeTokensReasoning = "native_tokens_reasoning"
    case nativeTokensCached = "native_tokens_cached"
    case latency
    case generationTime = "generation_time"
    case moderationLatency = "moderation_latency"
    case finishReason = "finish_reason"
    case nativeFinishReason = "native_finish_reason"
    case appId = "app_id"
    case sessionId = "session_id"
    case workspaceId = "workspace_id"
    case router
    case numMediaPrompt = "num_media_prompt"
    case numMediaCompletion = "num_media_completion"
    case numSearchResults = "num_search_results"
    case webSearchEngine = "web_search_engine"
  }
}

struct GenerationResponse: Decodable {
  let data: Generation
}
