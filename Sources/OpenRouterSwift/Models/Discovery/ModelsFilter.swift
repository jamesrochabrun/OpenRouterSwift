import Foundation

/// Query filters for `GET /api/v1/models`.
public struct ModelsFilter: Sendable {
  public enum Sort: String, Sendable {
    case pricingLowToHigh = "pricing-low-to-high"
    case contextHighToLow = "context-high-to-low"
    case throughputHighToLow = "throughput-high-to-low"
    case latencyLowToHigh = "latency-low-to-high"
    case mostPopular = "most-popular"
    case topWeekly = "top-weekly"
    case newest
  }

  public var category: String?
  public var supportedParameters: [String]?
  public var inputModalities: [String]?
  public var outputModalities: [String]?
  /// Free-text search.
  public var q: String?
  /// Model family, e.g. `"gpt"`, `"claude"`.
  public var arch: String?
  public var modelAuthors: [String]?
  public var providers: [String]?
  /// Minimum context length in tokens.
  public var context: Int?
  /// Price bounds in USD per million tokens.
  public var minPrice: Double?
  public var maxPrice: Double?
  public var minOutputPrice: Double?
  public var maxOutputPrice: Double?
  /// Only zero-data-retention endpoints.
  public var zdr: Bool?
  /// `"eu"` or `"us"`.
  public var region: String?
  public var distillable: Bool?
  public var offset: Int?
  /// Max 1000.
  public var limit: Int?
  public var sort: Sort?

  public init(
    category: String? = nil,
    supportedParameters: [String]? = nil,
    inputModalities: [String]? = nil,
    outputModalities: [String]? = nil,
    q: String? = nil,
    arch: String? = nil,
    modelAuthors: [String]? = nil,
    providers: [String]? = nil,
    context: Int? = nil,
    minPrice: Double? = nil,
    maxPrice: Double? = nil,
    minOutputPrice: Double? = nil,
    maxOutputPrice: Double? = nil,
    zdr: Bool? = nil,
    region: String? = nil,
    distillable: Bool? = nil,
    offset: Int? = nil,
    limit: Int? = nil,
    sort: Sort? = nil)
  {
    self.category = category
    self.supportedParameters = supportedParameters
    self.inputModalities = inputModalities
    self.outputModalities = outputModalities
    self.q = q
    self.arch = arch
    self.modelAuthors = modelAuthors
    self.providers = providers
    self.context = context
    self.minPrice = minPrice
    self.maxPrice = maxPrice
    self.minOutputPrice = minOutputPrice
    self.maxOutputPrice = maxOutputPrice
    self.zdr = zdr
    self.region = region
    self.distillable = distillable
    self.offset = offset
    self.limit = limit
    self.sort = sort
  }

  var queryItems: [URLQueryItem] {
    var items = [URLQueryItem]()
    func add(_ name: String, _ value: String?) {
      if let value {
        items.append(URLQueryItem(name: name, value: value))
      }
    }
    add("category", category)
    add("supported_parameters", supportedParameters?.joined(separator: ","))
    add("input_modalities", inputModalities?.joined(separator: ","))
    add("output_modalities", outputModalities?.joined(separator: ","))
    add("q", q)
    add("arch", arch)
    add("model_authors", modelAuthors?.joined(separator: ","))
    add("providers", providers?.joined(separator: ","))
    add("context", context.map(String.init))
    add("min_price", minPrice.map { String($0) })
    add("max_price", maxPrice.map { String($0) })
    add("min_output_price", minOutputPrice.map { String($0) })
    add("max_output_price", maxOutputPrice.map { String($0) })
    add("zdr", zdr.map { $0 ? "true" : "false" })
    add("region", region)
    add("distillable", distillable.map { $0 ? "true" : "false" })
    add("offset", offset.map(String.init))
    add("limit", limit.map(String.init))
    add("sort", sort?.rawValue)
    return items
  }
}
