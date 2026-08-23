import Foundation

// MARK: - Preset

/// A saved inference configuration (`GET /api/v1/presets`).
/// Invoke a preset by using `model: "@preset/slug"` in any inference request.
public struct Preset: Decodable, Sendable {
  public let id: String
  public let slug: String
  public let name: String?
  public let description: String?
  /// `active`, `disabled`, or `archived`.
  public let status: String?
  public let statusUpdatedAt: String?
  public let designatedVersionId: String?
  public let creatorUserId: String?
  public let workspaceId: String?
  public let createdAt: String?
  public let updatedAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case slug
    case name
    case description
    case status
    case statusUpdatedAt = "status_updated_at"
    case designatedVersionId = "designated_version_id"
    case creatorUserId = "creator_user_id"
    case workspaceId = "workspace_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

// MARK: - PresetVersion

/// A version of a preset's configuration.
public struct PresetVersion: Decodable, Sendable {
  public let id: String
  public let presetId: String?
  public let version: Int?
  /// The persisted request-config overlay (model, temperature, provider, tools, ...).
  public let config: JSONValue?
  public let systemPrompt: String?
  public let creatorId: String?
  public let createdAt: String?
  public let updatedAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case presetId = "preset_id"
    case version
    case config
    case systemPrompt = "system_prompt"
    case creatorId = "creator_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

// MARK: - PresetDetail

/// A preset together with its designated (active) version.
public struct PresetDetail: Decodable, Sendable {
  public let id: String
  public let slug: String
  public let name: String?
  public let description: String?
  public let status: String?
  public let designatedVersion: PresetVersion?
  public let createdAt: String?
  public let updatedAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case slug
    case name
    case description
    case status
    case designatedVersion = "designated_version"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

// MARK: - List envelopes

/// Paged list of presets.
public struct PresetList: Decodable, Sendable {
  public let data: [Preset]
  public let totalCount: Int?

  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}

/// Paged list of preset versions.
public struct PresetVersionList: Decodable, Sendable {
  public let data: [PresetVersion]
  public let totalCount: Int?

  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}

struct PresetDetailResponse: Decodable {
  let data: PresetDetail
}

struct PresetVersionResponse: Decodable {
  let data: PresetVersion
}
