import Foundation

// MARK: - KeyInfo

/// Result of `GET /api/v1/key` — information about the calling API key.
public struct KeyInfo: Decodable, Sendable {
  public let label: String?
  /// Credit limit for the key, `nil` when unlimited.
  public let limit: Double?
  public let limitRemaining: Double?
  /// Total usage in credits.
  public let usage: Double?
  public let usageDaily: Double?
  public let usageWeekly: Double?
  public let usageMonthly: Double?
  public let isFreeTier: Bool?
  public let isManagementKey: Bool?
  public let expiresAt: String?

  enum CodingKeys: String, CodingKey {
    case label
    case limit
    case limitRemaining = "limit_remaining"
    case usage
    case usageDaily = "usage_daily"
    case usageWeekly = "usage_weekly"
    case usageMonthly = "usage_monthly"
    case isFreeTier = "is_free_tier"
    case isManagementKey = "is_management_key"
    case expiresAt = "expires_at"
  }
}

struct KeyInfoResponse: Decodable {
  let data: KeyInfo
}

// MARK: - Credits

/// Result of `GET /api/v1/credits`.
public struct Credits: Decodable, Sendable {
  public let totalCredits: Double
  public let totalUsage: Double

  /// Remaining balance.
  public var remaining: Double {
    totalCredits - totalUsage
  }

  enum CodingKeys: String, CodingKey {
    case totalCredits = "total_credits"
    case totalUsage = "total_usage"
  }
}

struct CreditsResponse: Decodable {
  let data: Credits
}
