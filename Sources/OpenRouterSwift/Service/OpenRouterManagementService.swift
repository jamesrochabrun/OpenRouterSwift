import Foundation

/// Endpoints that require an OpenRouter **management key** (org administration):
/// key provisioning, BYOK, guardrails, workspaces, organization members, observability
/// destinations, and SCIM. Keep management keys out of client apps — this protocol is
/// separate from `OpenRouterService` so the type system enforces that split.
public protocol OpenRouterManagementService: Sendable {

  // MARK: Key provisioning

  /// `GET /api/v1/keys`
  func keys(includeDisabled: Bool?, offset: Int?, workspaceId: String?) async throws -> [ProvisionedKey]

  /// `POST /api/v1/keys` — the plaintext key is in `CreatedKey.key`, shown only once.
  func createKey(_ request: CreateKeyRequest) async throws -> CreatedKey

  /// `GET /api/v1/keys/{hash}`
  func key(hash: String) async throws -> ProvisionedKey

  /// `PATCH /api/v1/keys/{hash}`
  func updateKey(hash: String, _ request: UpdateKeyRequest) async throws -> ProvisionedKey

  /// `DELETE /api/v1/keys/{hash}`
  func deleteKey(hash: String) async throws -> Bool

  // MARK: BYOK

  /// `GET /api/v1/byok`
  func byokCredentials(offset: Int?, limit: Int?, provider: String?) async throws -> [ByokCredential]

  /// `POST /api/v1/byok`
  func createByokCredential(_ request: ByokRequest) async throws -> ByokCredential

  /// `GET /api/v1/byok/{id}`
  func byokCredential(id: String) async throws -> ByokCredential

  /// `PATCH /api/v1/byok/{id}` — pass `key` to rotate in place.
  func updateByokCredential(id: String, _ request: ByokRequest) async throws -> ByokCredential

  /// `DELETE /api/v1/byok/{id}`
  func deleteByokCredential(id: String) async throws -> Bool

  // MARK: Guardrails

  /// `GET /api/v1/guardrails`
  func guardrails(offset: Int?, limit: Int?) async throws -> [Guardrail]

  /// `POST /api/v1/guardrails`
  func createGuardrail(_ request: GuardrailRequest) async throws -> Guardrail

  /// `GET /api/v1/guardrails/{id}`
  func guardrail(id: String) async throws -> Guardrail

  /// `PATCH /api/v1/guardrails/{id}`
  func updateGuardrail(id: String, _ request: GuardrailRequest) async throws -> Guardrail

  /// `DELETE /api/v1/guardrails/{id}`
  func deleteGuardrail(id: String) async throws -> Bool

  /// `GET /api/v1/guardrails/{id}/assignments/keys`
  func guardrailKeyAssignments(id: String) async throws -> [GuardrailKeyAssignment]

  /// `POST /api/v1/guardrails/{id}/assignments/keys` — returns the number assigned.
  func assignGuardrailKeys(id: String, keyHashes: [String]) async throws -> Int

  /// `POST /api/v1/guardrails/{id}/assignments/keys/remove` — returns the number unassigned.
  func unassignGuardrailKeys(id: String, keyHashes: [String]) async throws -> Int

  /// `GET /api/v1/guardrails/{id}/assignments/members`
  func guardrailMemberAssignments(id: String) async throws -> [GuardrailMemberAssignment]

  /// `POST /api/v1/guardrails/{id}/assignments/members`
  func assignGuardrailMembers(id: String, memberUserIds: [String]) async throws -> Int

  /// `POST /api/v1/guardrails/{id}/assignments/members/remove`
  func unassignGuardrailMembers(id: String, memberUserIds: [String]) async throws -> Int

  // MARK: Workspaces

  /// `GET /api/v1/workspaces`
  func workspaces(offset: Int?, limit: Int?) async throws -> [Workspace]

  /// `POST /api/v1/workspaces`
  func createWorkspace(_ request: WorkspaceRequest) async throws -> Workspace

  /// `GET /api/v1/workspaces/{id}` — `id` accepts a UUID or slug.
  func workspace(id: String) async throws -> Workspace

  /// `PATCH /api/v1/workspaces/{id}`
  func updateWorkspace(id: String, _ request: WorkspaceRequest) async throws -> Workspace

  /// `DELETE /api/v1/workspaces/{id}`
  func deleteWorkspace(id: String) async throws -> Bool

  /// `GET /api/v1/workspaces/{id}/budgets`
  func workspaceBudgets(id: String) async throws -> [WorkspaceBudget]

  /// `PUT /api/v1/workspaces/{id}/budgets/{interval}` — upserts.
  /// `interval` is `daily`, `weekly`, `monthly`, or `lifetime`.
  func setWorkspaceBudget(id: String, interval: String, limitUSD: Double) async throws -> WorkspaceBudget

  /// `DELETE /api/v1/workspaces/{id}/budgets/{interval}`
  func deleteWorkspaceBudget(id: String, interval: String) async throws -> Bool

  /// `GET /api/v1/workspaces/{id}/members`
  func workspaceMembers(id: String) async throws -> [WorkspaceMember]

  /// `POST /api/v1/workspaces/{id}/members/add` — returns the number added.
  func addWorkspaceMembers(id: String, userIds: [String]) async throws -> Int

  /// `POST /api/v1/workspaces/{id}/members/remove` — returns the number removed.
  func removeWorkspaceMembers(id: String, userIds: [String]) async throws -> Int

  // MARK: Organization

  /// `GET /api/v1/organization/members`
  func organizationMembers(offset: Int?, limit: Int?) async throws -> [OrganizationMember]

  // MARK: Observability destinations

  /// `GET /api/v1/observability/destinations`
  func observabilityDestinations() async throws -> [ObservabilityDestination]

  /// `POST /api/v1/observability/destinations`
  func createObservabilityDestination(_ request: ObservabilityDestinationRequest) async throws -> ObservabilityDestination

  /// `GET /api/v1/observability/destinations/{id}`
  func observabilityDestination(id: String) async throws -> ObservabilityDestination

  /// `PATCH /api/v1/observability/destinations/{id}`
  func updateObservabilityDestination(id: String, _ request: ObservabilityDestinationRequest) async throws -> ObservabilityDestination

  /// `DELETE /api/v1/observability/destinations/{id}`
  func deleteObservabilityDestination(id: String) async throws -> Bool

  // MARK: SCIM

  /// `GET /api/v1/scim/groups` (read-only; groups are provisioned via the SCIM IdP flow).
  func scimGroups(offset: Int?, limit: Int?) async throws -> [ScimGroup]

  /// `GET /api/v1/scim/group-mappings`
  func scimGroupMappings(offset: Int?, limit: Int?) async throws -> [ScimGroupMapping]

  /// `POST /api/v1/scim/group-mappings` — `role` is `admin` or `member`.
  func createScimGroupMapping(scimGroupId: String, workspaceId: String, role: String) async throws -> ScimGroupMapping

  /// `PATCH /api/v1/scim/group-mappings/{id}`
  func updateScimGroupMapping(id: String, role: String) async throws -> ScimGroupMapping

  /// `DELETE /api/v1/scim/group-mappings/{id}?keep_members=`
  func deleteScimGroupMapping(id: String, keepMembers: Bool) async throws -> Bool
}
