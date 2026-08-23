import Foundation

// MARK: - Provider

/// A provider from `GET /api/v1/providers`.
public struct Provider: Decodable, Sendable {
  public let name: String
  public let slug: String
  public let privacyPolicyURL: String?
  public let termsOfServiceURL: String?
  public let statusPageURL: String?
  /// ISO-3166 alpha-2.
  public let headquarters: String?
  public let datacenters: [String]?

  enum CodingKeys: String, CodingKey {
    case name
    case slug
    case privacyPolicyURL = "privacy_policy_url"
    case termsOfServiceURL = "terms_of_service_url"
    case statusPageURL = "status_page_url"
    case headquarters
    case datacenters
  }
}

struct ProvidersResponse: Decodable {
  let data: [Provider]
}

// MARK: - ZDREndpoint

/// A zero-data-retention endpoint from `GET /api/v1/endpoints/zdr`.
public struct ZDREndpoint: Decodable, Sendable {
  public let name: String?
  public let modelId: String?
  public let modelName: String?
  public let providerName: String?
  public let tag: String?
  public let contextLength: Int?
  public let maxCompletionTokens: Int?
  public let quantization: String?
  public let supportedParameters: [String]?
  public let pricing: JSONValue?
  public let uptimeLast30m: Double?
  public let supportsImplicitCaching: Bool?

  enum CodingKeys: String, CodingKey {
    case name
    case modelId = "model_id"
    case modelName = "model_name"
    case providerName = "provider_name"
    case tag
    case contextLength = "context_length"
    case maxCompletionTokens = "max_completion_tokens"
    case quantization
    case supportedParameters = "supported_parameters"
    case pricing
    case uptimeLast30m = "uptime_last_30m"
    case supportsImplicitCaching = "supports_implicit_caching"
  }
}

struct ZDREndpointsResponse: Decodable {
  let data: [ZDREndpoint]
}

// MARK: - Benchmarks / classifications (heterogeneous — kept dynamic)

/// Result of `GET /api/v1/benchmarks`. Row shapes differ per source; kept dynamic.
public struct BenchmarksResponse: Decodable, Sendable {
  public let data: [JSONValue]
  public let meta: JSONValue?
}

/// Result of `GET /api/v1/classifications/task` — traffic share by task category.
public struct TaskClassifications: Decodable, Sendable {
  public let asOf: String?
  public let windowDays: Int?
  public let classifications: [JSONValue]
  public let macroCategories: [JSONValue]?

  enum CodingKeys: String, CodingKey {
    case asOf = "as_of"
    case windowDays = "window_days"
    case classifications
    case macroCategories = "macro_categories"
  }
}

struct TaskClassificationsResponse: Decodable {
  let data: TaskClassifications
}

// MARK: - Datasets

/// A row from `GET /api/v1/datasets/app-rankings`.
public struct AppRanking: Decodable, Sendable {
  public let rank: Int?
  public let appId: Int?
  public let appName: String?
  public let totalRequests: Int?
  /// Decimal string (64-bit safe).
  public let totalTokens: String?

  enum CodingKeys: String, CodingKey {
    case rank
    case appId = "app_id"
    case appName = "app_name"
    case totalRequests = "total_requests"
    case totalTokens = "total_tokens"
  }
}

/// A row from `GET /api/v1/datasets/rankings-daily`.
public struct DailyRanking: Decodable, Sendable {
  public let date: String?
  public let modelPermaslug: String?
  /// Decimal string (64-bit safe).
  public let totalTokens: String?

  enum CodingKeys: String, CodingKey {
    case date
    case modelPermaslug = "model_permaslug"
    case totalTokens = "total_tokens"
  }
}

/// A row from `GET /api/v1/datasets/session-cost`.
public struct SessionCost: Decodable, Sendable {
  public let appSlug: String?
  public let appName: String?
  public let modelPermaslug: String?
  public let turnRange: String?
  public let medianSessionCostUSD: Double?

  enum CodingKeys: String, CodingKey {
    case appSlug = "app_slug"
    case appName = "app_name"
    case modelPermaslug = "model_permaslug"
    case turnRange = "turn_range"
    case medianSessionCostUSD = "median_session_cost_usd"
  }
}

struct DatasetResponse<Row: Decodable>: Decodable {
  let data: [Row]
}
