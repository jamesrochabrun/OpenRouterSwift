import XCTest
@testable import OpenRouterSwift

final class ManagementTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterManagementService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.managementService(managementKey: "sk-or-mgmt", httpClient: mock)
  }

  func testCreateKeyReturnsPlaintextOnce() async throws {
    mock.enqueueJSON("""
      {"key": "sk-or-v1-plaintext",
       "data": {"hash": "abc123", "name": "ci-key", "disabled": false, "limit": 10}}
      """, statusCode: 201)

    let created = try await service.createKey(
      CreateKeyRequest(name: "ci-key", limit: 10, limitReset: "monthly"))

    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(request.url.absoluteString, "https://openrouter.ai/api/v1/keys")
    XCTAssertEqual(request.method.rawValue, "POST")
    XCTAssertEqual(request.headers["Authorization"], "Bearer sk-or-mgmt")
    let body = try bodyJSON(request)
    XCTAssertEqual(body["name"] as? String, "ci-key")
    XCTAssertEqual(body["limit_reset"] as? String, "monthly")

    XCTAssertEqual(created.key, "sk-or-v1-plaintext")
    XCTAssertEqual(created.data.hash, "abc123")
  }

  func testKeyPatchAndDeleteUseCorrectMethods() async throws {
    mock.enqueueJSON(#"{"data": {"hash": "abc123", "name": "renamed", "disabled": true}}"#)
    let updated = try await service.updateKey(hash: "abc123", UpdateKeyRequest(name: "renamed", disabled: true))
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "PATCH")
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/keys/abc123")
    XCTAssertEqual(updated.disabled, true)

    mock.enqueueJSON(#"{"deleted": true}"#)
    let deleted = try await service.deleteKey(hash: "abc123")
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "DELETE")
    XCTAssertTrue(deleted)
  }

  func testByokRotation() async throws {
    mock.enqueueJSON(#"{"data": {"id": "byok_1", "provider": "openai", "label": "sk-...abc", "disabled": false}}"#)
    _ = try await service.updateByokCredential(id: "byok_1", ByokRequest(key: "sk-new-raw-key"))
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "PATCH")
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/byok/byok_1")
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["key"] as? String, "sk-new-raw-key")
  }

  func testGuardrailAssignmentsUsePostRemoveEndpoints() async throws {
    mock.enqueueJSON(#"{"assigned_count": 2}"#)
    let assigned = try await service.assignGuardrailKeys(id: "g_1", keyHashes: ["h1", "h2"])
    XCTAssertEqual(
      mock.lastRequest?.url.absoluteString,
      "https://openrouter.ai/api/v1/guardrails/g_1/assignments/keys")
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "POST")
    XCTAssertEqual(assigned, 2)

    mock.enqueueJSON(#"{"unassigned_count": 1}"#)
    let removed = try await service.unassignGuardrailKeys(id: "g_1", keyHashes: ["h1"])
    XCTAssertEqual(
      mock.lastRequest?.url.absoluteString,
      "https://openrouter.ai/api/v1/guardrails/g_1/assignments/keys/remove")
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "POST")
    XCTAssertEqual(removed, 1)
  }

  func testWorkspaceBudgetUsesPut() async throws {
    mock.enqueueJSON(#"{"data": {"id": "b_1", "workspace_id": "w_1", "limit_usd": 100, "reset_interval": "monthly"}}"#)
    let budget = try await service.setWorkspaceBudget(id: "w_1", interval: "monthly", limitUSD: 100)
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "PUT")
    XCTAssertEqual(
      mock.lastRequest?.url.absoluteString,
      "https://openrouter.ai/api/v1/workspaces/w_1/budgets/monthly")
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["limit_usd"] as? Double, 100)
    XCTAssertEqual(budget.limitUSD, 100)
  }

  func testScimMappingDeleteRequiresKeepMembers() async throws {
    mock.enqueueJSON(#"{"deleted": true}"#)
    _ = try await service.deleteScimGroupMapping(id: "m_1", keepMembers: true)
    XCTAssertEqual(
      mock.lastRequest?.url.absoluteString,
      "https://openrouter.ai/api/v1/scim/group-mappings/m_1?keep_members=true")
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "DELETE")
  }

  func testOrganizationMembers() async throws {
    mock.enqueueJSON("""
      {"data": [{"id": "u_1", "email": "a@b.com", "first_name": "Ada", "last_name": null, "role": "org:admin"}],
       "total_count": 1}
      """)
    let members = try await service.organizationMembers(offset: nil, limit: nil)
    XCTAssertEqual(members.first?.role, "org:admin")
  }
}

final class ObservabilityDiscoveryTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.service(apiKey: "sk-or-test", httpClient: mock)
  }

  func testGenerationFeedback() async throws {
    mock.enqueueJSON(#"{"data": {"success": true}}"#)
    let ok = try await service.submitGenerationFeedback(
      generationId: "gen-1",
      category: .incorrectResponse,
      comment: "Wrong year")
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/generation/feedback")
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["generation_id"] as? String, "gen-1")
    XCTAssertEqual(body["category"] as? String, "incorrect_response")
    XCTAssertTrue(ok)
  }

  func testActivityAndProviders() async throws {
    mock.enqueueJSON("""
      {"data": [{"date": "2026-08-21", "model": "openai/gpt-4o", "requests": 42,
                 "prompt_tokens": 1000, "completion_tokens": 500, "reasoning_tokens": 0,
                 "usage": 1.23, "byok_usage_inference": 0}]}
      """)
    let rows = try await service.activity(filter: ActivityFilter(date: "2026-08-21"))
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/activity?date=2026-08-21")
    XCTAssertEqual(rows.first?.requests, 42)

    mock.enqueueJSON(#"{"data": [{"name": "OpenAI", "slug": "openai", "privacy_policy_url": "https://openai.com/privacy"}]}"#)
    let providers = try await service.providers()
    XCTAssertEqual(providers.first?.slug, "openai")
  }

  func testAnalyticsQuery() async throws {
    mock.enqueueJSON("""
      {"data": {"data": [{"model": "openai/gpt-4o", "total_cost": 12.5}],
                "metadata": {"row_count": 1, "truncated": false, "query_time_ms": 12.0}}}
      """)
    let result = try await service.analyticsQuery(
      AnalyticsQueryRequest(metrics: ["total_cost"], dimensions: ["model"], granularity: "day"))
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["metrics"] as? [String], ["total_cost"])
    XCTAssertEqual(result.rowCount, 1)
    XCTAssertEqual(result.rows.first?["total_cost"]?.doubleValue, 12.5)
  }
}
