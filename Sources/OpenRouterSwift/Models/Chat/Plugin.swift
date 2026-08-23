import Foundation

/// OpenRouter request plugins (`plugins` array). Each encodes as `{"id": ..., <config fields>}`.
public enum Plugin: Encodable, Sendable {
  /// Web search. Replaces model knowledge gaps with live results.
  case web(WebConfig? = nil)
  /// Fetches URLs referenced in the prompt.
  case webFetch(config: [String: JSONValue]? = nil)
  /// PDF/file parsing for `file` content parts.
  case fileParser(config: [String: JSONValue]? = nil)
  /// Context compression (replaces the removed `transforms: ["middle-out"]`).
  case contextCompression(ContextCompressionConfig? = nil)
  /// Input/output moderation.
  case moderation
  /// Heals malformed structured outputs.
  case responseHealing
  /// Automatic model routing.
  case autoRouter
  /// Cost-optimized routing.
  case paretoRouter
  /// Multi-model panel.
  case fusion(config: [String: JSONValue]? = nil)
  /// Forward-compatibility escape hatch for plugins this package doesn't model yet.
  case custom(id: String, config: [String: JSONValue] = [:])

  // MARK: - Configs

  public struct WebConfig: Encodable, Sendable {
    /// Search engine, e.g. `"native"` or `"exa"`.
    public var engine: String?
    public var maxResults: Int?
    public var searchContextSize: String?
    public var allowedDomains: [String]?
    public var excludedDomains: [String]?
    public var maxUses: Int?
    public var mode: String?

    public init(
      engine: String? = nil,
      maxResults: Int? = nil,
      searchContextSize: String? = nil,
      allowedDomains: [String]? = nil,
      excludedDomains: [String]? = nil,
      maxUses: Int? = nil,
      mode: String? = nil)
    {
      self.engine = engine
      self.maxResults = maxResults
      self.searchContextSize = searchContextSize
      self.allowedDomains = allowedDomains
      self.excludedDomains = excludedDomains
      self.maxUses = maxUses
      self.mode = mode
    }

    enum CodingKeys: String, CodingKey {
      case engine
      case maxResults = "max_results"
      case searchContextSize = "search_context_size"
      case allowedDomains = "allowed_domains"
      case excludedDomains = "excluded_domains"
      case maxUses = "max_uses"
      case mode
    }
  }

  public struct ContextCompressionConfig: Encodable, Sendable {
    /// Compression engine, e.g. `"middle-out"`.
    public var engine: String?
    public var enabled: Bool?

    public init(engine: String? = nil, enabled: Bool? = nil) {
      self.engine = engine
      self.enabled = enabled
    }
  }

  // MARK: - Encoding

  var id: String {
    switch self {
    case .web: return "web"
    case .webFetch: return "web-fetch"
    case .fileParser: return "file-parser"
    case .contextCompression: return "context-compression"
    case .moderation: return "moderation"
    case .responseHealing: return "response-healing"
    case .autoRouter: return "auto-router"
    case .paretoRouter: return "pareto-router"
    case .fusion: return "fusion"
    case .custom(let id, _): return id
    }
  }

  private struct IDKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue _: Int) { nil }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: IDKey.self)
    try container.encode(id, forKey: IDKey(stringValue: "id"))
    switch self {
    case .web(let config):
      try config?.encode(to: encoder)

    case .contextCompression(let config):
      try config?.encode(to: encoder)

    case .webFetch(let config), .fileParser(let config), .fusion(let config):
      try encodeDictionary(config, into: &container)

    case .custom(_, let config):
      var mutable = container
      try encodeDictionary(config, into: &mutable)

    case .moderation, .responseHealing, .autoRouter, .paretoRouter:
      break
    }
  }

  private func encodeDictionary(_ config: [String: JSONValue]?, into container: inout KeyedEncodingContainer<IDKey>) throws {
    guard let config else { return }
    for (key, value) in config {
      try container.encode(value, forKey: IDKey(stringValue: key))
    }
  }
}
