import Foundation

/// OpenRouter provider routing preferences (`provider` request field).
/// See https://openrouter.ai/docs — provider routing.
public struct ProviderPreferences: Encodable, Sendable {
  public enum Sort: String, Encodable, Sendable {
    case price
    case throughput
    case latency
    case exacto
  }

  public enum DataCollection: String, Encodable, Sendable {
    case allow
    case deny
  }

  /// Per-token-type USD price caps. Values are strings per the OpenRouter spec, e.g. `"0.000008"`.
  public struct MaxPrice: Encodable, Sendable {
    public var prompt: String?
    public var completion: String?
    public var image: String?
    public var audio: String?
    public var request: String?

    public init(
      prompt: String? = nil,
      completion: String? = nil,
      image: String? = nil,
      audio: String? = nil,
      request: String? = nil)
    {
      self.prompt = prompt
      self.completion = completion
      self.image = image
      self.audio = audio
      self.request = request
    }
  }

  /// Whether to allow backup providers when the primary is unavailable.
  public var allowFallbacks: Bool?
  /// Ordered list of provider slugs to try first.
  public var order: [String]?
  /// Restrict routing to only these providers.
  public var only: [String]?
  /// Never route to these providers.
  public var ignore: [String]?
  public var sort: Sort?
  public var maxPrice: MaxPrice?
  public var dataCollection: DataCollection?
  /// Restrict to zero-data-retention endpoints.
  public var zdr: Bool?
  /// Only route to providers that support every parameter in the request.
  public var requireParameters: Bool?
  /// Allowed quantization levels, e.g. `["fp16", "fp8"]`.
  public var quantizations: [String]?
  /// Preferred maximum latency in seconds.
  public var preferredMaxLatency: Double?
  /// Preferred minimum throughput in tokens/second.
  public var preferredMinThroughput: Double?
  public var enforceDistillableText: Bool?

  public init(
    allowFallbacks: Bool? = nil,
    order: [String]? = nil,
    only: [String]? = nil,
    ignore: [String]? = nil,
    sort: Sort? = nil,
    maxPrice: MaxPrice? = nil,
    dataCollection: DataCollection? = nil,
    zdr: Bool? = nil,
    requireParameters: Bool? = nil,
    quantizations: [String]? = nil,
    preferredMaxLatency: Double? = nil,
    preferredMinThroughput: Double? = nil,
    enforceDistillableText: Bool? = nil)
  {
    self.allowFallbacks = allowFallbacks
    self.order = order
    self.only = only
    self.ignore = ignore
    self.sort = sort
    self.maxPrice = maxPrice
    self.dataCollection = dataCollection
    self.zdr = zdr
    self.requireParameters = requireParameters
    self.quantizations = quantizations
    self.preferredMaxLatency = preferredMaxLatency
    self.preferredMinThroughput = preferredMinThroughput
    self.enforceDistillableText = enforceDistillableText
  }

  enum CodingKeys: String, CodingKey {
    case allowFallbacks = "allow_fallbacks"
    case order
    case only
    case ignore
    case sort
    case maxPrice = "max_price"
    case dataCollection = "data_collection"
    case zdr
    case requireParameters = "require_parameters"
    case quantizations
    case preferredMaxLatency = "preferred_max_latency"
    case preferredMinThroughput = "preferred_min_throughput"
    case enforceDistillableText = "enforce_distillable_text"
  }
}
