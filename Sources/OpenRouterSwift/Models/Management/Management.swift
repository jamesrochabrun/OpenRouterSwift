import Foundation

// MARK: - Shared envelopes

struct DataEnvelope<T: Decodable>: Decodable {
  let data: T
}

struct PagedEnvelope<T: Decodable>: Decodable {
  let data: [T]
  let totalCount: Int?

  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}

struct DeletedResponse: Decodable {
  let deleted: Bool
}

// MARK: - Provisioned keys

/// An API key managed via the provisioning API (`/keys`).
public struct ProvisionedKey: Decodable, Sendable {
  public let hash: String
  public let name: String?
  public let label: String?
  public let disabled: Bool?
  public let limit: Double?
  public let limitRemaining: Double?
  /// `daily`, `weekly`, `monthly`, or `nil`.
  public let limitReset: String?
  public let includeByokInLimit: Bool?
  public let usage: Double?
  public let usageDaily: Double?
  public let usageWeekly: Double?
  public let usageMonthly: Double?
  public let creatorUserId: String?
  public let workspaceId: String?
  public let createdAt: String?
  public let updatedAt: String?
  public let expiresAt: String?

  enum CodingKeys: String, CodingKey {
    case hash
    case name
    case label
    case disabled
    case limit
    case limitRemaining = "limit_remaining"
    case limitReset = "limit_reset"
    case includeByokInLimit = "include_byok_in_limit"
    case usage
    case usageDaily = "usage_daily"
    case usageWeekly = "usage_weekly"
    case usageMonthly = "usage_monthly"
    case creatorUserId = "creator_user_id"
    case workspaceId = "workspace_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case expiresAt = "expires_at"
  }
}

/// Body for `POST /api/v1/keys`. The plaintext key is returned once, in `CreatedKey.key`.
public struct CreateKeyRequest: Encodable, Sendable {
  public var name: String
  public var limit: Double?
  /// `daily`, `weekly`, or `monthly`.
  public var limitReset: String?
  public var includeByokInLimit: Bool?
  /// UTC ISO-8601 date-time.
  public var expiresAt: String?
  public var workspaceId: String?

  public init(
    name: String,
    limit: Double? = nil,
    limitReset: String? = nil,
    includeByokInLimit: Bool? = nil,
    expiresAt: String? = nil,
    workspaceId: String? = nil)
  {
    self.name = name
    self.limit = limit
    self.limitReset = limitReset
    self.includeByokInLimit = includeByokInLimit
    self.expiresAt = expiresAt
    self.workspaceId = workspaceId
  }

  enum CodingKeys: String, CodingKey {
    case name
    case limit
    case limitReset = "limit_reset"
    case includeByokInLimit = "include_byok_in_limit"
    case expiresAt = "expires_at"
    case workspaceId = "workspace_id"
  }
}

/// Result of `POST /api/v1/keys` — `key` is the plaintext secret, shown only once.
public struct CreatedKey: Decodable, Sendable {
  public let key: String
  public let data: ProvisionedKey
}

/// Body for `PATCH /api/v1/keys/{hash}` (`expiresAt` cannot be changed).
public struct UpdateKeyRequest: Encodable, Sendable {
  public var name: String?
  public var disabled: Bool?
  public var limit: Double?
  public var limitReset: String?
  public var includeByokInLimit: Bool?

  public init(
    name: String? = nil,
    disabled: Bool? = nil,
    limit: Double? = nil,
    limitReset: String? = nil,
    includeByokInLimit: Bool? = nil)
  {
    self.name = name
    self.disabled = disabled
    self.limit = limit
    self.limitReset = limitReset
    self.includeByokInLimit = includeByokInLimit
  }

  enum CodingKeys: String, CodingKey {
    case name
    case disabled
    case limit
    case limitReset = "limit_reset"
    case includeByokInLimit = "include_byok_in_limit"
  }
}

// MARK: - BYOK

/// A bring-your-own-key credential. The raw provider key is never returned.
public struct ByokCredential: Decodable, Sendable {
  public let id: String
  public let provider: String?
  /// Masked snippet of the key.
  public let label: String?
  public let name: String?
  public let disabled: Bool?
  public let isFallback: Bool?
  public let allowedModels: [String]?
  public let createdAt: String?
  public let workspaceId: String?

  enum CodingKeys: String, CodingKey {
    case id
    case provider
    case label
    case name
    case disabled
    case isFallback = "is_fallback"
    case allowedModels = "allowed_models"
    case createdAt = "created_at"
    case workspaceId = "workspace_id"
  }
}

/// Body for `POST /api/v1/byok` and (without `provider`) `PATCH /api/v1/byok/{id}`.
public struct ByokRequest: Encodable, Sendable {
  /// Provider slug — required on create, not changeable on update.
  public var provider: String?
  /// The raw provider API key; on PATCH, rotates it in place.
  public var key: String?
  public var name: String?
  public var disabled: Bool?
  public var isFallback: Bool?
  public var allowedModels: [String]?
  public var workspaceId: String?

  public init(
    provider: String? = nil,
    key: String? = nil,
    name: String? = nil,
    disabled: Bool? = nil,
    isFallback: Bool? = nil,
    allowedModels: [String]? = nil,
    workspaceId: String? = nil)
  {
    self.provider = provider
    self.key = key
    self.name = name
    self.disabled = disabled
    self.isFallback = isFallback
    self.allowedModels = allowedModels
    self.workspaceId = workspaceId
  }

  enum CodingKeys: String, CodingKey {
    case provider
    case key
    case name
    case disabled
    case isFallback = "is_fallback"
    case allowedModels = "allowed_models"
    case workspaceId = "workspace_id"
  }
}

// MARK: - Guardrails

/// A content/spend policy (`/guardrails`). Used for both responses and (as `Encodable`
/// via `GuardrailRequest`) create/update bodies.
public struct Guardrail: Decodable, Sendable {
  public let id: String
  public let name: String?
  public let description: String?
  public let allowedModels: [String]?
  public let ignoredModels: [String]?
  public let allowedProviders: [String]?
  public let ignoredProviders: [String]?
  public let limitUSD: Double?
  public let resetInterval: String?
  public let includeByokInBudgets: Bool?
  public let contentFilters: [JSONValue]?
  public let contentFilterBuiltins: [JSONValue]?
  public let createdAt: String?
  public let updatedAt: String?
  public let workspaceId: String?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case allowedModels = "allowed_models"
    case ignoredModels = "ignored_models"
    case allowedProviders = "allowed_providers"
    case ignoredProviders = "ignored_providers"
    case limitUSD = "limit_usd"
    case resetInterval = "reset_interval"
    case includeByokInBudgets = "include_byok_in_budgets"
    case contentFilters = "content_filters"
    case contentFilterBuiltins = "content_filter_builtins"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case workspaceId = "workspace_id"
  }
}

/// Body for `POST /api/v1/guardrails` and `PATCH /api/v1/guardrails/{id}`.
public struct GuardrailRequest: Encodable, Sendable {
  public struct ContentFilter: Encodable, Sendable {
    public var pattern: String
    /// `redact`, `block`, or `flag`.
    public var action: String
    public var label: String?

    public init(pattern: String, action: String, label: String? = nil) {
      self.pattern = pattern
      self.action = action
      self.label = label
    }
  }

  public struct BuiltinFilter: Encodable, Sendable {
    /// `email`, `phone`, `ssn`, `credit-card`, `ip-address`, `person-name`, `address`,
    /// `regex-prompt-injection`.
    public var slug: String
    public var action: String
    /// `user_only` or `all_messages`.
    public var scanScope: String?

    public init(slug: String, action: String, scanScope: String? = nil) {
      self.slug = slug
      self.action = action
      self.scanScope = scanScope
    }

    enum CodingKeys: String, CodingKey {
      case slug
      case action
      case scanScope = "scan_scope"
    }
  }

  /// Required on create.
  public var name: String?
  public var description: String?
  public var allowedModels: [String]?
  public var ignoredModels: [String]?
  public var allowedProviders: [String]?
  public var ignoredProviders: [String]?
  /// Must be set together with `resetInterval` on create.
  public var limitUSD: Double?
  public var resetInterval: String?
  public var includeByokInBudgets: Bool?
  public var contentFilters: [ContentFilter]?
  public var contentFilterBuiltins: [BuiltinFilter]?
  public var workspaceId: String?

  public init(
    name: String? = nil,
    description: String? = nil,
    allowedModels: [String]? = nil,
    ignoredModels: [String]? = nil,
    allowedProviders: [String]? = nil,
    ignoredProviders: [String]? = nil,
    limitUSD: Double? = nil,
    resetInterval: String? = nil,
    includeByokInBudgets: Bool? = nil,
    contentFilters: [ContentFilter]? = nil,
    contentFilterBuiltins: [BuiltinFilter]? = nil,
    workspaceId: String? = nil)
  {
    self.name = name
    self.description = description
    self.allowedModels = allowedModels
    self.ignoredModels = ignoredModels
    self.allowedProviders = allowedProviders
    self.ignoredProviders = ignoredProviders
    self.limitUSD = limitUSD
    self.resetInterval = resetInterval
    self.includeByokInBudgets = includeByokInBudgets
    self.contentFilters = contentFilters
    self.contentFilterBuiltins = contentFilterBuiltins
    self.workspaceId = workspaceId
  }

  enum CodingKeys: String, CodingKey {
    case name
    case description
    case allowedModels = "allowed_models"
    case ignoredModels = "ignored_models"
    case allowedProviders = "allowed_providers"
    case ignoredProviders = "ignored_providers"
    case limitUSD = "limit_usd"
    case resetInterval = "reset_interval"
    case includeByokInBudgets = "include_byok_in_budgets"
    case contentFilters = "content_filters"
    case contentFilterBuiltins = "content_filter_builtins"
    case workspaceId = "workspace_id"
  }
}

/// A guardrail↔key assignment row.
public struct GuardrailKeyAssignment: Decodable, Sendable {
  public let id: String?
  public let guardrailId: String?
  public let keyHash: String?
  public let keyName: String?
  public let keyLabel: String?
  public let assignedBy: String?
  public let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case guardrailId = "guardrail_id"
    case keyHash = "key_hash"
    case keyName = "key_name"
    case keyLabel = "key_label"
    case assignedBy = "assigned_by"
    case createdAt = "created_at"
  }
}

/// A guardrail↔member assignment row.
public struct GuardrailMemberAssignment: Decodable, Sendable {
  public let id: String?
  public let guardrailId: String?
  public let userId: String?
  public let organizationId: String?
  public let assignedBy: String?
  public let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case guardrailId = "guardrail_id"
    case userId = "user_id"
    case organizationId = "organization_id"
    case assignedBy = "assigned_by"
    case createdAt = "created_at"
  }
}

struct AssignKeysRequest: Encodable {
  let keyHashes: [String]

  enum CodingKeys: String, CodingKey {
    case keyHashes = "key_hashes"
  }
}

struct AssignMembersRequest: Encodable {
  let memberUserIds: [String]

  enum CodingKeys: String, CodingKey {
    case memberUserIds = "member_user_ids"
  }
}

struct AssignedCountResponse: Decodable {
  let assignedCount: Int?
  let unassignedCount: Int?

  enum CodingKeys: String, CodingKey {
    case assignedCount = "assigned_count"
    case unassignedCount = "unassigned_count"
  }
}

// MARK: - Workspaces

public struct Workspace: Decodable, Sendable {
  public let id: String
  public let name: String?
  public let slug: String?
  public let description: String?
  public let createdAt: String?
  public let updatedAt: String?
  public let createdBy: String?
  public let defaultGuardrailId: String?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case slug
    case description
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case createdBy = "created_by"
    case defaultGuardrailId = "default_guardrail_id"
  }
}

/// Body for `POST /api/v1/workspaces` (name + slug required) and `PATCH .../{id}`.
public struct WorkspaceRequest: Encodable, Sendable {
  public var name: String?
  /// Lowercase-hyphen slug.
  public var slug: String?
  public var description: String?
  public var defaultGuardrailId: String?

  public init(
    name: String? = nil,
    slug: String? = nil,
    description: String? = nil,
    defaultGuardrailId: String? = nil)
  {
    self.name = name
    self.slug = slug
    self.description = description
    self.defaultGuardrailId = defaultGuardrailId
  }

  enum CodingKeys: String, CodingKey {
    case name
    case slug
    case description
    case defaultGuardrailId = "default_guardrail_id"
  }
}

/// A workspace spend budget. `resetInterval == nil` means lifetime.
public struct WorkspaceBudget: Decodable, Sendable {
  public let id: String?
  public let workspaceId: String?
  public let limitUSD: Double?
  public let resetInterval: String?
  public let createdAt: String?
  public let updatedAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case workspaceId = "workspace_id"
    case limitUSD = "limit_usd"
    case resetInterval = "reset_interval"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

struct PutBudgetRequest: Encodable {
  let limitUSD: Double
  let includeByokInBudgets: Bool?

  enum CodingKeys: String, CodingKey {
    case limitUSD = "limit_usd"
    case includeByokInBudgets = "include_byok_in_budgets"
  }
}

public struct WorkspaceMember: Decodable, Sendable {
  public let id: String?
  public let workspaceId: String?
  public let userId: String?
  /// `admin` or `member`.
  public let role: String?
  public let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case workspaceId = "workspace_id"
    case userId = "user_id"
    case role
    case createdAt = "created_at"
  }
}

struct UserIdsRequest: Encodable {
  let userIds: [String]

  enum CodingKeys: String, CodingKey {
    case userIds = "user_ids"
  }
}

struct MembersChangedResponse: Decodable {
  let addedCount: Int?
  let removedCount: Int?

  enum CodingKeys: String, CodingKey {
    case addedCount = "added_count"
    case removedCount = "removed_count"
  }
}

// MARK: - Organization

public struct OrganizationMember: Decodable, Sendable {
  public let id: String
  public let email: String?
  public let firstName: String?
  public let lastName: String?
  /// `org:admin` or `org:member`.
  public let role: String?

  enum CodingKeys: String, CodingKey {
    case id
    case email
    case firstName = "first_name"
    case lastName = "last_name"
    case role
  }
}

// MARK: - Observability destinations

/// A log-export destination (Datadog, Langfuse, S3, webhook, ...).
public struct ObservabilityDestination: Decodable, Sendable {
  public let id: String
  public let name: String?
  public let type: String?
  /// Per-type config; shape varies across the 17 destination types.
  public let config: JSONValue?
  public let enabled: Bool?
  public let privacyMode: Bool?
  public let samplingRate: Double?
  public let createdAt: String?
  public let updatedAt: String?
  public let workspaceId: String?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case type
    case config
    case enabled
    case privacyMode = "privacy_mode"
    case samplingRate = "sampling_rate"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case workspaceId = "workspace_id"
  }
}

/// Body for `POST /api/v1/observability/destinations` and `PATCH .../{id}`
/// (`type` and `workspaceId` are create-only).
public struct ObservabilityDestinationRequest: Encodable, Sendable {
  public var name: String?
  public var type: String?
  public var config: JSONValue?
  public var enabled: Bool?
  public var privacyMode: Bool?
  public var samplingRate: Double?
  public var apiKeyHashes: [String]?
  public var filterRules: JSONValue?
  public var workspaceId: String?

  public init(
    name: String? = nil,
    type: String? = nil,
    config: JSONValue? = nil,
    enabled: Bool? = nil,
    privacyMode: Bool? = nil,
    samplingRate: Double? = nil,
    apiKeyHashes: [String]? = nil,
    filterRules: JSONValue? = nil,
    workspaceId: String? = nil)
  {
    self.name = name
    self.type = type
    self.config = config
    self.enabled = enabled
    self.privacyMode = privacyMode
    self.samplingRate = samplingRate
    self.apiKeyHashes = apiKeyHashes
    self.filterRules = filterRules
    self.workspaceId = workspaceId
  }

  enum CodingKeys: String, CodingKey {
    case name
    case type
    case config
    case enabled
    case privacyMode = "privacy_mode"
    case samplingRate = "sampling_rate"
    case apiKeyHashes = "api_key_hashes"
    case filterRules = "filter_rules"
    case workspaceId = "workspace_id"
  }
}

// MARK: - SCIM

/// A SCIM-provisioned group (read-only).
public struct ScimGroup: Decodable, Sendable {
  public let id: String
  public let organizationId: String?
  public let displayName: String?
  public let externalId: String?
  public let createdAt: String?
  public let updatedAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case organizationId = "organization_id"
    case displayName = "display_name"
    case externalId = "external_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// A SCIM group → workspace mapping.
public struct ScimGroupMapping: Decodable, Sendable {
  public let id: String
  public let organizationId: String?
  public let scimGroupId: String?
  public let workspaceId: String?
  /// `admin` or `member`.
  public let role: String?
  public let createdAt: String?
  public let updatedAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case organizationId = "organization_id"
    case scimGroupId = "scim_group_id"
    case workspaceId = "workspace_id"
    case role
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

struct CreateScimGroupMappingRequest: Encodable {
  let scimGroupId: String
  let workspaceId: String
  let role: String

  enum CodingKeys: String, CodingKey {
    case scimGroupId = "scim_group_id"
    case workspaceId = "workspace_id"
    case role
  }
}

struct UpdateScimGroupMappingRequest: Encodable {
  let role: String
}
