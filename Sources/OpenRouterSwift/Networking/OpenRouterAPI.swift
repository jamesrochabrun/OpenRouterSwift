import Foundation
import SwiftOpenAI

/// Every OpenRouter endpoint, mapped to its path and HTTP method.
/// Paths are relative to the configured base URL (default `https://openrouter.ai`)
/// and all live under `/api/v1`.
enum OpenRouterAPI {
  // Inference
  case chatCompletions
  case messages
  case responses
  case embeddings
  case images
  case videos
  case video(jobId: String)
  case videoContent(jobId: String)
  case audioSpeech
  case audioTranscriptions
  case rerank

  // Presets
  case presets
  case preset(slug: String)
  case presetVersions(slug: String)
  case presetVersion(slug: String, version: String)
  case presetChatCompletions(slug: String)
  case presetMessages(slug: String)
  case presetResponses(slug: String)

  // Discovery
  case models
  case model(author: String, slug: String)
  case modelEndpoints(author: String, slug: String)
  case modelsCount
  case modelsUser
  case embeddingsModels
  case imagesModels
  case imageModelEndpoints(author: String, slug: String)
  case videosModels
  case providers
  case endpointsZDR
  case benchmarks
  case classificationsTask

  // Observability
  case generation
  case generationContent
  case generationFeedback
  case activity
  case analyticsMeta
  case analyticsQuery

  // Account
  case key
  case credits
  case authKeysCode
  case authKeys

  // Files
  case files
  case file(id: String)
  case fileContent(id: String)

  // Datasets
  case datasetsAppRankings
  case datasetsRankingsDaily
  case datasetsSessionCost

  // Management (management key required)
  case keys
  case keyByHash(hash: String)
  case byok
  case byokById(id: String)
  case guardrails
  case guardrail(id: String)
  case guardrailKeyAssignments(id: String)
  case guardrailKeyAssignmentsRemove(id: String)
  case guardrailMemberAssignments(id: String)
  case guardrailMemberAssignmentsRemove(id: String)
  case guardrailsAllKeyAssignments
  case guardrailsAllMemberAssignments
  case workspaces
  case workspace(id: String)
  case workspaceBudgets(id: String)
  case workspaceBudget(id: String, interval: String)
  case workspaceMembers(id: String)
  case workspaceMembersAdd(id: String)
  case workspaceMembersRemove(id: String)
  case organizationMembers
  case observabilityDestinations
  case observabilityDestination(id: String)
  case scimGroups
  case scimGroupMappings
  case scimGroupMapping(id: String)

  /// The default method for the endpoint; several CRUD paths are called with an
  /// explicit override (PATCH/PUT/DELETE) via the transport.
  var method: HTTPMethod {
    switch self {
    case .chatCompletions, .messages, .responses, .embeddings, .images, .videos,
         .audioSpeech, .audioTranscriptions, .rerank,
         .presetChatCompletions, .presetMessages, .presetResponses,
         .generationFeedback, .analyticsQuery, .authKeysCode, .authKeys,
         .guardrailKeyAssignmentsRemove, .guardrailMemberAssignmentsRemove,
         .workspaceMembersAdd, .workspaceMembersRemove:
      return .post
    default:
      return .get
    }
  }

  var path: String {
    let base = "/api/v1"
    switch self {
    case .chatCompletions: return "\(base)/chat/completions"
    case .messages: return "\(base)/messages"
    case .responses: return "\(base)/responses"
    case .embeddings: return "\(base)/embeddings"
    case .images: return "\(base)/images"
    case .videos: return "\(base)/videos"
    case .video(let jobId): return "\(base)/videos/\(jobId)"
    case .videoContent(let jobId): return "\(base)/videos/\(jobId)/content"
    case .audioSpeech: return "\(base)/audio/speech"
    case .audioTranscriptions: return "\(base)/audio/transcriptions"
    case .rerank: return "\(base)/rerank"
    case .presets: return "\(base)/presets"
    case .preset(let slug): return "\(base)/presets/\(slug)"
    case .presetVersions(let slug): return "\(base)/presets/\(slug)/versions"
    case .presetVersion(let slug, let version): return "\(base)/presets/\(slug)/versions/\(version)"
    case .presetChatCompletions(let slug): return "\(base)/presets/\(slug)/chat/completions"
    case .presetMessages(let slug): return "\(base)/presets/\(slug)/messages"
    case .presetResponses(let slug): return "\(base)/presets/\(slug)/responses"
    case .models: return "\(base)/models"
    case .model(let author, let slug): return "\(base)/model/\(author)/\(slug)"
    case .modelEndpoints(let author, let slug): return "\(base)/models/\(author)/\(slug)/endpoints"
    case .modelsCount: return "\(base)/models/count"
    case .modelsUser: return "\(base)/models/user"
    case .embeddingsModels: return "\(base)/embeddings/models"
    case .imagesModels: return "\(base)/images/models"
    case .imageModelEndpoints(let author, let slug): return "\(base)/images/models/\(author)/\(slug)/endpoints"
    case .videosModels: return "\(base)/videos/models"
    case .providers: return "\(base)/providers"
    case .endpointsZDR: return "\(base)/endpoints/zdr"
    case .benchmarks: return "\(base)/benchmarks"
    case .classificationsTask: return "\(base)/classifications/task"
    case .generation: return "\(base)/generation"
    case .generationContent: return "\(base)/generation/content"
    case .generationFeedback: return "\(base)/generation/feedback"
    case .activity: return "\(base)/activity"
    case .analyticsMeta: return "\(base)/analytics/meta"
    case .analyticsQuery: return "\(base)/analytics/query"
    case .key: return "\(base)/key"
    case .credits: return "\(base)/credits"
    case .authKeysCode: return "\(base)/auth/keys/code"
    case .authKeys: return "\(base)/auth/keys"
    case .files: return "\(base)/files"
    case .file(let id): return "\(base)/files/\(id)"
    case .fileContent(let id): return "\(base)/files/\(id)/content"
    case .datasetsAppRankings: return "\(base)/datasets/app-rankings"
    case .datasetsRankingsDaily: return "\(base)/datasets/rankings-daily"
    case .datasetsSessionCost: return "\(base)/datasets/session-cost"
    case .keys: return "\(base)/keys"
    case .keyByHash(let hash): return "\(base)/keys/\(hash)"
    case .byok: return "\(base)/byok"
    case .byokById(let id): return "\(base)/byok/\(id)"
    case .guardrails: return "\(base)/guardrails"
    case .guardrail(let id): return "\(base)/guardrails/\(id)"
    case .guardrailKeyAssignments(let id): return "\(base)/guardrails/\(id)/assignments/keys"
    case .guardrailKeyAssignmentsRemove(let id): return "\(base)/guardrails/\(id)/assignments/keys/remove"
    case .guardrailMemberAssignments(let id): return "\(base)/guardrails/\(id)/assignments/members"
    case .guardrailMemberAssignmentsRemove(let id): return "\(base)/guardrails/\(id)/assignments/members/remove"
    case .guardrailsAllKeyAssignments: return "\(base)/guardrails/assignments/keys"
    case .guardrailsAllMemberAssignments: return "\(base)/guardrails/assignments/members"
    case .workspaces: return "\(base)/workspaces"
    case .workspace(let id): return "\(base)/workspaces/\(id)"
    case .workspaceBudgets(let id): return "\(base)/workspaces/\(id)/budgets"
    case .workspaceBudget(let id, let interval): return "\(base)/workspaces/\(id)/budgets/\(interval)"
    case .workspaceMembers(let id): return "\(base)/workspaces/\(id)/members"
    case .workspaceMembersAdd(let id): return "\(base)/workspaces/\(id)/members/add"
    case .workspaceMembersRemove(let id): return "\(base)/workspaces/\(id)/members/remove"
    case .organizationMembers: return "\(base)/organization/members"
    case .observabilityDestinations: return "\(base)/observability/destinations"
    case .observabilityDestination(let id): return "\(base)/observability/destinations/\(id)"
    case .scimGroups: return "\(base)/scim/groups"
    case .scimGroupMappings: return "\(base)/scim/group-mappings"
    case .scimGroupMapping(let id): return "\(base)/scim/group-mappings/\(id)"
    }
  }
}
