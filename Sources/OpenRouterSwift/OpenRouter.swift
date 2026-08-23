import Foundation
import SwiftOpenAI

// MARK: - Re-exported transport types

/// The HTTP transport abstraction (from SwiftOpenAI) that OpenRouterSwift rides on.
/// Inject a custom implementation for testing or bespoke networking. This typealias is
/// the single deliberate SwiftOpenAI type at the public API boundary.
public typealias OpenRouterHTTPClient = SwiftOpenAI.HTTPClient

// MARK: - OpenRouterConfiguration

/// Client-wide configuration: base URL, app attribution headers, and metadata opt-in.
public struct OpenRouterConfiguration: Sendable {
  /// Base URL, override for proxies. Default `https://openrouter.ai`.
  public var baseURL: String
  /// Sent as `HTTP-Referer` — your app's URL, for openrouter.ai rankings.
  public var appReferer: String?
  /// Sent as `X-OpenRouter-Title` (and legacy `X-Title`) — your app's display name.
  public var appTitle: String?
  /// Sent as `X-OpenRouter-Categories` — marketplace categories.
  public var categories: [String]?
  /// Sends `X-OpenRouter-Metadata: enabled` so inference responses include `openrouter_metadata`.
  public var metadataEnabled: Bool
  /// Extra headers merged into every request.
  public var extraHeaders: [String: String]

  public init(
    baseURL: String = "https://openrouter.ai",
    appReferer: String? = nil,
    appTitle: String? = nil,
    categories: [String]? = nil,
    metadataEnabled: Bool = false,
    extraHeaders: [String: String] = [:])
  {
    self.baseURL = baseURL
    self.appReferer = appReferer
    self.appTitle = appTitle
    self.categories = categories
    self.metadataEnabled = metadataEnabled
    self.extraHeaders = extraHeaders
  }

  func headers(apiKey: String) -> [String: String] {
    var headers = extraHeaders
    headers["Authorization"] = "Bearer \(apiKey)"
    if let appReferer {
      headers["HTTP-Referer"] = appReferer
    }
    if let appTitle {
      headers["X-OpenRouter-Title"] = appTitle
      headers["X-Title"] = appTitle
    }
    if let categories, !categories.isEmpty {
      headers["X-OpenRouter-Categories"] = categories.joined(separator: ",")
    }
    if metadataEnabled {
      headers["X-OpenRouter-Metadata"] = "enabled"
    }
    return headers
  }
}

// MARK: - OpenRouter

/// Entry point. Build a service with your inference API key:
///
/// ```swift
/// let service = OpenRouter.service(
///   apiKey: "sk-or-...",
///   configuration: .init(appReferer: "https://myapp.com", appTitle: "MyApp"))
/// ```
public enum OpenRouter {
  /// Creates a service backed by an OpenRouter **inference key**.
  public static func service(
    apiKey: String,
    configuration: OpenRouterConfiguration = OpenRouterConfiguration(),
    httpClient: OpenRouterHTTPClient? = nil,
    debugEnabled: Bool = false)
    -> OpenRouterService
  {
    let transport = OpenRouterTransport(
      httpClient: httpClient ?? HTTPClientFactory.createDefault(),
      baseURL: configuration.baseURL,
      defaultHeaders: configuration.headers(apiKey: apiKey),
      debugEnabled: debugEnabled)
    return DefaultOpenRouterService(transport: transport)
  }

  /// Creates a service backed by an OpenRouter **management key** for org administration
  /// (key provisioning, BYOK, guardrails, workspaces, SCIM). Never ship a management key
  /// in a client app.
  public static func managementService(
    managementKey: String,
    configuration: OpenRouterConfiguration = OpenRouterConfiguration(),
    httpClient: OpenRouterHTTPClient? = nil,
    debugEnabled: Bool = false)
    -> OpenRouterManagementService
  {
    let transport = OpenRouterTransport(
      httpClient: httpClient ?? HTTPClientFactory.createDefault(),
      baseURL: configuration.baseURL,
      defaultHeaders: configuration.headers(apiKey: managementKey),
      debugEnabled: debugEnabled)
    return DefaultOpenRouterManagementService(transport: transport)
  }
}
