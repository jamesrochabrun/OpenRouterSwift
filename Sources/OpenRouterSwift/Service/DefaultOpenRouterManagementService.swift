import Foundation
import SwiftOpenAI

/// Default `OpenRouterManagementService` implementation.
/// Create instances via `OpenRouter.managementService(managementKey:...)`.
final class DefaultOpenRouterManagementService: OpenRouterManagementService, @unchecked Sendable {
  private let transport: OpenRouterTransport

  init(transport: OpenRouterTransport) {
    self.transport = transport
  }

  private func paging(offset: Int?, limit: Int?) -> [URLQueryItem] {
    var items = [URLQueryItem]()
    if let offset { items.append(URLQueryItem(name: "offset", value: String(offset))) }
    if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
    return items
  }

  // MARK: Key provisioning

  func keys(includeDisabled: Bool?, offset: Int?, workspaceId: String?) async throws -> [ProvisionedKey] {
    var queryItems = [URLQueryItem]()
    if let includeDisabled {
      queryItems.append(URLQueryItem(name: "include_disabled", value: includeDisabled ? "true" : "false"))
    }
    if let offset {
      queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
    }
    if let workspaceId {
      queryItems.append(URLQueryItem(name: "workspace_id", value: workspaceId))
    }
    let response: DataEnvelope<[ProvisionedKey]> = try await transport.fetch(.keys, queryItems: queryItems)
    return response.data
  }

  func createKey(_ request: CreateKeyRequest) async throws -> CreatedKey {
    try await transport.fetch(.keys, method: .post, body: request)
  }

  func key(hash: String) async throws -> ProvisionedKey {
    let response: DataEnvelope<ProvisionedKey> = try await transport.fetch(.keyByHash(hash: hash))
    return response.data
  }

  func updateKey(hash: String, _ request: UpdateKeyRequest) async throws -> ProvisionedKey {
    let response: DataEnvelope<ProvisionedKey> = try await transport.fetch(
      .keyByHash(hash: hash),
      method: .patch,
      body: request)
    return response.data
  }

  func deleteKey(hash: String) async throws -> Bool {
    let response: DeletedResponse = try await transport.fetch(.keyByHash(hash: hash), method: .delete)
    return response.deleted
  }

  // MARK: BYOK

  func byokCredentials(offset: Int?, limit: Int?, provider: String?) async throws -> [ByokCredential] {
    var queryItems = paging(offset: offset, limit: limit)
    if let provider {
      queryItems.append(URLQueryItem(name: "provider", value: provider))
    }
    let response: PagedEnvelope<ByokCredential> = try await transport.fetch(.byok, queryItems: queryItems)
    return response.data
  }

  func createByokCredential(_ request: ByokRequest) async throws -> ByokCredential {
    let response: DataEnvelope<ByokCredential> = try await transport.fetch(.byok, method: .post, body: request)
    return response.data
  }

  func byokCredential(id: String) async throws -> ByokCredential {
    let response: DataEnvelope<ByokCredential> = try await transport.fetch(.byokById(id: id))
    return response.data
  }

  func updateByokCredential(id: String, _ request: ByokRequest) async throws -> ByokCredential {
    let response: DataEnvelope<ByokCredential> = try await transport.fetch(
      .byokById(id: id),
      method: .patch,
      body: request)
    return response.data
  }

  func deleteByokCredential(id: String) async throws -> Bool {
    let response: DeletedResponse = try await transport.fetch(.byokById(id: id), method: .delete)
    return response.deleted
  }

  // MARK: Guardrails

  func guardrails(offset: Int?, limit: Int?) async throws -> [Guardrail] {
    let response: PagedEnvelope<Guardrail> = try await transport.fetch(
      .guardrails,
      queryItems: paging(offset: offset, limit: limit))
    return response.data
  }

  func createGuardrail(_ request: GuardrailRequest) async throws -> Guardrail {
    let response: DataEnvelope<Guardrail> = try await transport.fetch(.guardrails, method: .post, body: request)
    return response.data
  }

  func guardrail(id: String) async throws -> Guardrail {
    let response: DataEnvelope<Guardrail> = try await transport.fetch(.guardrail(id: id))
    return response.data
  }

  func updateGuardrail(id: String, _ request: GuardrailRequest) async throws -> Guardrail {
    let response: DataEnvelope<Guardrail> = try await transport.fetch(
      .guardrail(id: id),
      method: .patch,
      body: request)
    return response.data
  }

  func deleteGuardrail(id: String) async throws -> Bool {
    let response: DeletedResponse = try await transport.fetch(.guardrail(id: id), method: .delete)
    return response.deleted
  }

  func guardrailKeyAssignments(id: String) async throws -> [GuardrailKeyAssignment] {
    let response: PagedEnvelope<GuardrailKeyAssignment> = try await transport.fetch(
      .guardrailKeyAssignments(id: id))
    return response.data
  }

  func assignGuardrailKeys(id: String, keyHashes: [String]) async throws -> Int {
    let response: AssignedCountResponse = try await transport.fetch(
      .guardrailKeyAssignments(id: id),
      method: .post,
      body: AssignKeysRequest(keyHashes: keyHashes))
    return response.assignedCount ?? 0
  }

  func unassignGuardrailKeys(id: String, keyHashes: [String]) async throws -> Int {
    let response: AssignedCountResponse = try await transport.fetch(
      .guardrailKeyAssignmentsRemove(id: id),
      body: AssignKeysRequest(keyHashes: keyHashes))
    return response.unassignedCount ?? 0
  }

  func guardrailMemberAssignments(id: String) async throws -> [GuardrailMemberAssignment] {
    let response: PagedEnvelope<GuardrailMemberAssignment> = try await transport.fetch(
      .guardrailMemberAssignments(id: id))
    return response.data
  }

  func assignGuardrailMembers(id: String, memberUserIds: [String]) async throws -> Int {
    let response: AssignedCountResponse = try await transport.fetch(
      .guardrailMemberAssignments(id: id),
      method: .post,
      body: AssignMembersRequest(memberUserIds: memberUserIds))
    return response.assignedCount ?? 0
  }

  func unassignGuardrailMembers(id: String, memberUserIds: [String]) async throws -> Int {
    let response: AssignedCountResponse = try await transport.fetch(
      .guardrailMemberAssignmentsRemove(id: id),
      body: AssignMembersRequest(memberUserIds: memberUserIds))
    return response.unassignedCount ?? 0
  }

  // MARK: Workspaces

  func workspaces(offset: Int?, limit: Int?) async throws -> [Workspace] {
    let response: PagedEnvelope<Workspace> = try await transport.fetch(
      .workspaces,
      queryItems: paging(offset: offset, limit: limit))
    return response.data
  }

  func createWorkspace(_ request: WorkspaceRequest) async throws -> Workspace {
    let response: DataEnvelope<Workspace> = try await transport.fetch(.workspaces, method: .post, body: request)
    return response.data
  }

  func workspace(id: String) async throws -> Workspace {
    let response: DataEnvelope<Workspace> = try await transport.fetch(.workspace(id: id))
    return response.data
  }

  func updateWorkspace(id: String, _ request: WorkspaceRequest) async throws -> Workspace {
    let response: DataEnvelope<Workspace> = try await transport.fetch(
      .workspace(id: id),
      method: .patch,
      body: request)
    return response.data
  }

  func deleteWorkspace(id: String) async throws -> Bool {
    let response: DeletedResponse = try await transport.fetch(.workspace(id: id), method: .delete)
    return response.deleted
  }

  func workspaceBudgets(id: String) async throws -> [WorkspaceBudget] {
    let response: DataEnvelope<[WorkspaceBudget]> = try await transport.fetch(.workspaceBudgets(id: id))
    return response.data
  }

  func setWorkspaceBudget(id: String, interval: String, limitUSD: Double) async throws -> WorkspaceBudget {
    let response: DataEnvelope<WorkspaceBudget> = try await transport.fetch(
      .workspaceBudget(id: id, interval: interval),
      method: .put,
      body: PutBudgetRequest(limitUSD: limitUSD, includeByokInBudgets: nil))
    return response.data
  }

  func deleteWorkspaceBudget(id: String, interval: String) async throws -> Bool {
    let response: DeletedResponse = try await transport.fetch(
      .workspaceBudget(id: id, interval: interval),
      method: .delete)
    return response.deleted
  }

  func workspaceMembers(id: String) async throws -> [WorkspaceMember] {
    let response: PagedEnvelope<WorkspaceMember> = try await transport.fetch(.workspaceMembers(id: id))
    return response.data
  }

  func addWorkspaceMembers(id: String, userIds: [String]) async throws -> Int {
    let response: MembersChangedResponse = try await transport.fetch(
      .workspaceMembersAdd(id: id),
      body: UserIdsRequest(userIds: userIds))
    return response.addedCount ?? 0
  }

  func removeWorkspaceMembers(id: String, userIds: [String]) async throws -> Int {
    let response: MembersChangedResponse = try await transport.fetch(
      .workspaceMembersRemove(id: id),
      body: UserIdsRequest(userIds: userIds))
    return response.removedCount ?? 0
  }

  // MARK: Organization

  func organizationMembers(offset: Int?, limit: Int?) async throws -> [OrganizationMember] {
    let response: PagedEnvelope<OrganizationMember> = try await transport.fetch(
      .organizationMembers,
      queryItems: paging(offset: offset, limit: limit))
    return response.data
  }

  // MARK: Observability destinations

  func observabilityDestinations() async throws -> [ObservabilityDestination] {
    let response: PagedEnvelope<ObservabilityDestination> = try await transport.fetch(.observabilityDestinations)
    return response.data
  }

  func createObservabilityDestination(_ request: ObservabilityDestinationRequest) async throws -> ObservabilityDestination {
    let response: DataEnvelope<ObservabilityDestination> = try await transport.fetch(
      .observabilityDestinations,
      method: .post,
      body: request)
    return response.data
  }

  func observabilityDestination(id: String) async throws -> ObservabilityDestination {
    let response: DataEnvelope<ObservabilityDestination> = try await transport.fetch(
      .observabilityDestination(id: id))
    return response.data
  }

  func updateObservabilityDestination(id: String, _ request: ObservabilityDestinationRequest) async throws -> ObservabilityDestination {
    let response: DataEnvelope<ObservabilityDestination> = try await transport.fetch(
      .observabilityDestination(id: id),
      method: .patch,
      body: request)
    return response.data
  }

  func deleteObservabilityDestination(id: String) async throws -> Bool {
    let response: DeletedResponse = try await transport.fetch(
      .observabilityDestination(id: id),
      method: .delete)
    return response.deleted
  }

  // MARK: SCIM

  func scimGroups(offset: Int?, limit: Int?) async throws -> [ScimGroup] {
    let response: PagedEnvelope<ScimGroup> = try await transport.fetch(
      .scimGroups,
      queryItems: paging(offset: offset, limit: limit))
    return response.data
  }

  func scimGroupMappings(offset: Int?, limit: Int?) async throws -> [ScimGroupMapping] {
    let response: PagedEnvelope<ScimGroupMapping> = try await transport.fetch(
      .scimGroupMappings,
      queryItems: paging(offset: offset, limit: limit))
    return response.data
  }

  func createScimGroupMapping(scimGroupId: String, workspaceId: String, role: String) async throws -> ScimGroupMapping {
    let response: DataEnvelope<ScimGroupMapping> = try await transport.fetch(
      .scimGroupMappings,
      method: .post,
      body: CreateScimGroupMappingRequest(scimGroupId: scimGroupId, workspaceId: workspaceId, role: role))
    return response.data
  }

  func updateScimGroupMapping(id: String, role: String) async throws -> ScimGroupMapping {
    let response: DataEnvelope<ScimGroupMapping> = try await transport.fetch(
      .scimGroupMapping(id: id),
      method: .patch,
      body: UpdateScimGroupMappingRequest(role: role))
    return response.data
  }

  func deleteScimGroupMapping(id: String, keepMembers: Bool) async throws -> Bool {
    let response: DeletedResponse = try await transport.fetch(
      .scimGroupMapping(id: id),
      method: .delete,
      queryItems: [URLQueryItem(name: "keep_members", value: keepMembers ? "true" : "false")])
    return response.deleted
  }
}
