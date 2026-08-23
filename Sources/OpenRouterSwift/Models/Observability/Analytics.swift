import Foundation

// MARK: - GenerationContent

/// Result of `GET /api/v1/generation/content?id=` — the stored input/output of a generation.
public struct GenerationContent: Decodable, Sendable {
  /// `{"prompt": ...}` or `{"messages": [...]}`.
  public let input: JSONValue?
  public let output: Output?
  public let error: JSONValue?

  public struct Output: Decodable, Sendable {
    public let completion: String?
    public let reasoning: String?
  }
}

struct GenerationContentResponse: Decodable {
  let data: GenerationContent
}

// MARK: - GenerationFeedback

/// Category for `POST /api/v1/generation/feedback`.
public enum GenerationFeedbackCategory: String, Encodable, Sendable {
  case latency
  case incoherence
  case incorrectResponse = "incorrect_response"
  case formatting
  case billing
  case apiError = "api_error"
  case other
}

struct GenerationFeedbackRequest: Encodable {
  let generationId: String
  let category: GenerationFeedbackCategory
  let comment: String?

  enum CodingKeys: String, CodingKey {
    case generationId = "generation_id"
    case category
    case comment
  }
}

struct GenerationFeedbackResponse: Decodable {
  struct Payload: Decodable {
    let success: Bool
  }

  let data: Payload
}

// MARK: - ActivityRow

/// A row from `GET /api/v1/activity` (last 30 days, grouped per endpoint per day).
public struct ActivityRow: Decodable, Sendable {
  public let date: String?
  public let model: String?
  public let modelPermaslug: String?
  public let endpointId: String?
  public let providerName: String?
  public let requests: Int?
  public let promptTokens: Int?
  public let completionTokens: Int?
  public let reasoningTokens: Int?
  /// Spend in credits.
  public let usage: Double?
  public let byokUsageInference: Double?
  public let workspaceId: String?

  enum CodingKeys: String, CodingKey {
    case date
    case model
    case modelPermaslug = "model_permaslug"
    case endpointId = "endpoint_id"
    case providerName = "provider_name"
    case requests
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case reasoningTokens = "reasoning_tokens"
    case usage
    case byokUsageInference = "byok_usage_inference"
    case workspaceId = "workspace_id"
  }
}

struct ActivityResponse: Decodable {
  let data: [ActivityRow]
}

/// Query filters for `GET /api/v1/activity`.
public struct ActivityFilter: Sendable {
  /// `YYYY-MM-DD`, within the last 30 days.
  public var date: String?
  public var apiKeyHash: String?
  public var userId: String?
  /// Only `"workspace"` is supported.
  public var groupBy: String?
  public var workspaceId: String?

  public init(
    date: String? = nil,
    apiKeyHash: String? = nil,
    userId: String? = nil,
    groupBy: String? = nil,
    workspaceId: String? = nil)
  {
    self.date = date
    self.apiKeyHash = apiKeyHash
    self.userId = userId
    self.groupBy = groupBy
    self.workspaceId = workspaceId
  }

  var queryItems: [URLQueryItem] {
    var items = [URLQueryItem]()
    if let date { items.append(URLQueryItem(name: "date", value: date)) }
    if let apiKeyHash { items.append(URLQueryItem(name: "api_key_hash", value: apiKeyHash)) }
    if let userId { items.append(URLQueryItem(name: "user_id", value: userId)) }
    if let groupBy { items.append(URLQueryItem(name: "group_by", value: groupBy)) }
    if let workspaceId { items.append(URLQueryItem(name: "workspace_id", value: workspaceId)) }
    return items
  }
}

// MARK: - Analytics

/// Result of `GET /api/v1/analytics/meta` — the dimensions/metrics vocabulary for queries.
public struct AnalyticsMeta: Decodable, Sendable {
  public let dimensions: [Field]
  public let metrics: [Metric]
  public let granularities: [Field]
  public let operators: [Operator]

  public struct Field: Decodable, Sendable {
    public let name: String
    public let displayLabel: String?

    enum CodingKeys: String, CodingKey {
      case name
      case displayLabel = "display_label"
    }
  }

  public struct Metric: Decodable, Sendable {
    public let name: String
    public let displayLabel: String?
    public let displayFormat: String?
    public let isRate: Bool?

    enum CodingKeys: String, CodingKey {
      case name
      case displayLabel = "display_label"
      case displayFormat = "display_format"
      case isRate = "is_rate"
    }
  }

  public struct Operator: Decodable, Sendable {
    public let name: String
    public let valueType: String?

    enum CodingKeys: String, CodingKey {
      case name
      case valueType = "value_type"
    }
  }
}

struct AnalyticsMetaResponse: Decodable {
  let data: AnalyticsMeta
}

/// Request body for `POST /api/v1/analytics/query`.
public struct AnalyticsQueryRequest: Encodable, Sendable {
  public struct Filter: Encodable, Sendable {
    public var field: String
    /// `eq`, `neq`, `in`, `not_in`, `gt`, `gte`, `lt`, `lte`.
    public var `operator`: String
    public var value: JSONValue
    public var includeUnset: Bool?

    public init(field: String, operator: String, value: JSONValue, includeUnset: Bool? = nil) {
      self.field = field
      self.operator = `operator`
      self.value = value
      self.includeUnset = includeUnset
    }

    enum CodingKeys: String, CodingKey {
      case field
      case `operator`
      case value
      case includeUnset = "include_unset"
    }
  }

  public struct TimeRange: Encodable, Sendable {
    /// ISO-8601 date-times.
    public var start: String
    public var end: String

    public init(start: String, end: String) {
      self.start = start
      self.end = end
    }
  }

  public struct OrderBy: Encodable, Sendable {
    public var field: String
    /// `asc` or `desc`.
    public var direction: String

    public init(field: String, direction: String) {
      self.field = field
      self.direction = direction
    }
  }

  public var metrics: [String]
  /// Max 2.
  public var dimensions: [String]?
  public var filters: [Filter]?
  /// `minute`, `hour`, `day`, `week`, `month`.
  public var granularity: String?
  public var timeRange: TimeRange?
  public var limit: Int?
  public var orderBy: OrderBy?

  public init(
    metrics: [String],
    dimensions: [String]? = nil,
    filters: [Filter]? = nil,
    granularity: String? = nil,
    timeRange: TimeRange? = nil,
    limit: Int? = nil,
    orderBy: OrderBy? = nil)
  {
    self.metrics = metrics
    self.dimensions = dimensions
    self.filters = filters
    self.granularity = granularity
    self.timeRange = timeRange
    self.limit = limit
    self.orderBy = orderBy
  }

  enum CodingKeys: String, CodingKey {
    case metrics
    case dimensions
    case filters
    case granularity
    case timeRange = "time_range"
    case limit
    case orderBy = "order_by"
  }
}

/// Result of `POST /api/v1/analytics/query`. Rows are untyped (shape depends on the query).
public struct AnalyticsQueryResult: Decodable, Sendable {
  public let rows: [JSONValue]
  public let rowCount: Int?
  public let truncated: Bool?
  public let warnings: [String]?

  struct Envelope: Decodable {
    struct Payload: Decodable {
      struct Metadata: Decodable {
        let rowCount: Int?
        let truncated: Bool?

        enum CodingKeys: String, CodingKey {
          case rowCount = "row_count"
          case truncated
        }
      }

      let data: [JSONValue]
      let metadata: Metadata?
      let warnings: [String]?
    }

    let data: Payload
  }

  public init(from decoder: Decoder) throws {
    let envelope = try Envelope(from: decoder)
    rows = envelope.data.data
    rowCount = envelope.data.metadata?.rowCount
    truncated = envelope.data.metadata?.truncated
    warnings = envelope.data.warnings
  }
}
