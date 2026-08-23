import XCTest
@testable import OpenRouterSwift

final class OAuthTests: XCTestCase {
  func testPKCEGeneratesS256ChallengeOnApplePlatforms() {
    let pkce = OpenRouterOAuth.PKCE()
    XCTAssertEqual(pkce.codeVerifier.count, 64)
    #if canImport(CryptoKit)
    XCTAssertEqual(pkce.method, .s256)
    XCTAssertNotEqual(pkce.codeChallenge, pkce.codeVerifier)
    XCTAssertFalse(pkce.codeChallenge.contains("="))
    XCTAssertFalse(pkce.codeChallenge.contains("+"))
    XCTAssertFalse(pkce.codeChallenge.contains("/"))
    #endif
  }

  func testAuthorizationURL() throws {
    let pkce = OpenRouterOAuth.PKCE()
    let url = OpenRouterOAuth.authorizationURL(
      callbackURL: URL(string: "https://myapp.com/callback")!,
      pkce: pkce)
    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    XCTAssertEqual(components.host, "openrouter.ai")
    XCTAssertEqual(components.path, "/auth")
    let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
    XCTAssertEqual(query["callback_url"], "https://myapp.com/callback")
    XCTAssertEqual(query["code_challenge"], pkce.codeChallenge)
    XCTAssertEqual(query["code_challenge_method"], pkce.method.rawValue)
  }

  func testExchangeCodePostsToAuthKeys() async throws {
    let mock = MockHTTPClient()
    mock.enqueueJSON(#"{"key": "sk-or-v1-new", "user_id": "user_123"}"#)

    let pkce = OpenRouterOAuth.PKCE()
    let result = try await OpenRouterOAuth.exchangeCode("the-code", pkce: pkce, httpClient: mock)

    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(request.url.absoluteString, "https://openrouter.ai/api/v1/auth/keys")
    XCTAssertEqual(request.method.rawValue, "POST")
    XCTAssertNil(request.headers["Authorization"])
    let body = try bodyJSON(request)
    XCTAssertEqual(body["code"] as? String, "the-code")
    XCTAssertEqual(body["code_verifier"] as? String, pkce.codeVerifier)
    XCTAssertEqual(body["code_challenge_method"] as? String, pkce.method.rawValue)

    XCTAssertEqual(result.key, "sk-or-v1-new")
    XCTAssertEqual(result.userId, "user_123")
  }
}
