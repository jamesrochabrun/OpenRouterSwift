import Foundation
import SwiftOpenAI
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

/// OAuth PKCE flow for obtaining a user-scoped API key without ever handling their password:
///
/// 1. `let pkce = OpenRouterOAuth.PKCE()` — keep `pkce.codeVerifier` around.
/// 2. Open `OpenRouterOAuth.authorizationURL(callbackURL:pkce:)` in a browser.
/// 3. OpenRouter redirects to your callback with `?code=...`.
/// 4. `let key = try await OpenRouterOAuth.exchangeCode(code, pkce: pkce)`.
public enum OpenRouterOAuth {

  // MARK: - PKCE

  public struct PKCE: Sendable {
    public enum Method: String, Sendable {
      case s256 = "S256"
      case plain
    }

    public let codeVerifier: String
    public let codeChallenge: String
    public let method: Method

    /// Generates a fresh verifier/challenge pair. Uses S256 everywhere — CryptoKit on
    /// Apple platforms, swift-crypto on Linux — with a `plain` fallback for any platform
    /// lacking both.
    public init() {
      let verifier = Self.randomVerifier()
      codeVerifier = verifier
      #if canImport(CryptoKit) || canImport(Crypto)
      let digest = SHA256.hash(data: Data(verifier.utf8))
      codeChallenge = Data(digest).base64URLEncoded
      method = .s256
      #else
      codeChallenge = verifier
      method = .plain
      #endif
    }

    private static func randomVerifier() -> String {
      // RFC 7636 unreserved characters, 64 chars.
      let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
      var generator = SystemRandomNumberGenerator()
      return String((0..<64).map { _ in alphabet.randomElement(using: &generator)! })
    }
  }

  // MARK: - Step 2: authorization URL

  /// The URL to open in a browser. `callbackURL` must be https or a localhost URL.
  public static func authorizationURL(
    callbackURL: URL,
    pkce: PKCE,
    baseURL: String = "https://openrouter.ai")
    -> URL
  {
    var components = URLComponents(string: baseURL)!
    components.path = "/auth"
    components.queryItems = [
      URLQueryItem(name: "callback_url", value: callbackURL.absoluteString),
      URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: pkce.method.rawValue),
    ]
    return components.url!
  }

  // MARK: - Step 4: code exchange

  /// Result of `POST /api/v1/auth/keys`.
  public struct KeyExchangeResponse: Decodable, Sendable {
    /// The new user-scoped inference API key.
    public let key: String
    public let userId: String?

    enum CodingKeys: String, CodingKey {
      case key
      case userId = "user_id"
    }
  }

  struct ExchangeRequest: Encodable {
    let code: String
    let codeVerifier: String
    let codeChallengeMethod: String

    enum CodingKeys: String, CodingKey {
      case code
      case codeVerifier = "code_verifier"
      case codeChallengeMethod = "code_challenge_method"
    }
  }

  /// `POST /api/v1/auth/keys` — exchanges the callback `code` for an API key.
  /// Unauthenticated by design (you don't have a key yet), so it lives outside
  /// `OpenRouterService`.
  public static func exchangeCode(
    _ code: String,
    pkce: PKCE,
    baseURL: String = "https://openrouter.ai",
    httpClient: OpenRouterHTTPClient? = nil)
    async throws -> KeyExchangeResponse
  {
    let transport = OpenRouterTransport(
      httpClient: httpClient ?? HTTPClientFactory.createDefault(),
      baseURL: baseURL,
      defaultHeaders: [:],
      debugEnabled: false)
    return try await transport.fetch(
      .authKeys,
      body: ExchangeRequest(
        code: code,
        codeVerifier: pkce.codeVerifier,
        codeChallengeMethod: pkce.method.rawValue))
  }
}

extension Data {
  var base64URLEncoded: String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
