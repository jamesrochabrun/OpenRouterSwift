import Foundation

// MARK: - FileObject

/// A stored file (OpenRouter-native shape; pass `provider` query for OpenAI/Anthropic shapes,
/// which this type decodes leniently — `bytes`/`created_at` variants land in the same fields).
public struct FileObject: Decodable, Sendable {
  public let id: String
  public let filename: String?
  public let mimeType: String?
  public let sizeBytes: Int?
  public let createdAt: JSONValue?
  public let downloadable: Bool?
  public let type: String?

  enum CodingKeys: String, CodingKey {
    case id
    case filename
    case mimeType = "mime_type"
    case sizeBytes = "size_bytes"
    case bytes
    case createdAt = "created_at"
    case downloadable
    case type
    case object
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    filename = try container.decodeIfPresent(String.self, forKey: .filename)
    mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
    sizeBytes = try container.decodeIfPresent(Int.self, forKey: .sizeBytes)
      ?? container.decodeIfPresent(Int.self, forKey: .bytes)
    createdAt = try container.decodeIfPresent(JSONValue.self, forKey: .createdAt)
    downloadable = try container.decodeIfPresent(Bool.self, forKey: .downloadable)
    type = try container.decodeIfPresent(String.self, forKey: .type)
      ?? container.decodeIfPresent(String.self, forKey: .object)
  }
}

// MARK: - FileList

/// Result of `GET /api/v1/files`.
public struct FileList: Decodable, Sendable {
  public let data: [FileObject]
  public let cursor: String?
  public let hasMore: Bool?
  public let firstId: String?
  public let lastId: String?

  enum CodingKeys: String, CodingKey {
    case data
    case cursor
    case hasMore = "has_more"
    case firstId = "first_id"
    case lastId = "last_id"
  }
}

/// Result of `DELETE /api/v1/files/{file_id}`.
public struct FileDeleted: Decodable, Sendable {
  public let id: String?
  public let type: String?
  public let deleted: Bool?

  enum CodingKeys: String, CodingKey {
    case id
    case type
    case deleted
    case object
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id)
    type = try container.decodeIfPresent(String.self, forKey: .type)
      ?? container.decodeIfPresent(String.self, forKey: .object)
    deleted = try container.decodeIfPresent(Bool.self, forKey: .deleted)
  }
}
