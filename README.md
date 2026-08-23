# OpenRouterSwift

A Swift client that makes [OpenRouter](https://openrouter.ai) a first-class citizen: the API
mirrors OpenRouter's endpoints, naming, and request shapes exactly — provider routing, model
fallbacks, plugins, reasoning tokens, usage/cost accounting, and the full discovery and
management surface. Built on modern Swift concurrency; transport shared with
[SwiftOpenAI](https://github.com/jamesrochabrun/SwiftOpenAI).

> Contributing or implementing endpoints (human or agent)? Read
> [INSTRUCTIONS.md](INSTRUCTIONS.md) first — it holds the invariants, the add-an-endpoint
> checklist, and the SSE rules.

## Install

```swift
dependencies: [
  .package(url: "https://github.com/jamesrochabrun/OpenRouterSwift", from: "0.1.0")
]
```

## Quick start

```swift
import OpenRouterSwift

let service = OpenRouter.service(
  apiKey: "sk-or-...",
  configuration: .init(
    appReferer: "https://myapp.com",   // optional, for openrouter.ai rankings
    appTitle: "MyApp"))

// Chat
let response = try await service.chatCompletion(
  ChatCompletionRequest(
    model: "openai/gpt-4o",
    messages: [.user("Hello!")]))
print(response.choices.first?.message.content ?? "")
print("cost: $\(response.usage?.cost ?? 0)")

// Streaming — usage (incl. cost) arrives on the final chunk
let stream = try await service.chatCompletionStream(
  ChatCompletionRequest(model: "openai/gpt-4o", messages: [.user("Hello!")]))
for try await chunk in stream {
  if let delta = chunk.choices?.first?.delta?.content { print(delta, terminator: "") }
}

// Provider routing + model fallbacks + plugins
let routed = try await service.chatCompletion(
  ChatCompletionRequest(
    model: "anthropic/claude-sonnet-4.5",
    models: ["openai/gpt-4o"],                      // fallbacks, tried in order
    messages: [.user("Search the web for today's news")],
    provider: ProviderPreferences(sort: .throughput, zdr: true),
    plugins: [.web()],
    reasoning: Reasoning(effort: .high)))
```

### Smart model routing

Routing is a request-level feature, not a separate endpoint. All of it is supported:

- `model: "openrouter/auto"` — let OpenRouter pick the model
- `plugins: [.autoRouter]` / `.autoBetaRouter` / `.paretoRouter` (cost-optimized) / `.fusion` (multi-model)
- `models: [...]` — ordered fallbacks when the primary model fails
- `provider: ProviderPreferences(sort: .price | .throughput | .latency | .exacto, maxPrice:, zdr:, ...)`
- `model: "@preset/slug"` — saved routing config via the presets API

Anything not yet typed passes through `extraBody`:

```swift
ChatCompletionRequest(model: "m", messages: [.user("x")],
                      extraBody: ["brand_new_param": .bool(true)])
```

## Endpoint → Swift method map

Status: ✅ implemented · ⬜ planned (phase in parens). Protocols: `OpenRouterService`
(inference key) unless marked **[mgmt]** = `OpenRouterManagementService` (management key).

### Inference

| Endpoint | Swift | Status |
|---|---|---|
| POST /chat/completions | `chatCompletion(_:)` | ✅ |
| POST /chat/completions (stream) | `chatCompletionStream(_:)` | ✅ |
| POST /messages (Anthropic format) | `message(_:)` / `messageStream(_:)` | ✅ |
| POST /responses (stateless — no `store`/`previous_response_id`) | `response(_:)` / `responseStream(_:)` | ✅ |
| POST /embeddings | `embeddings(_:)` | ✅ |
| POST /rerank | `rerank(_:)` | ✅ |
| POST /images (+ streaming) | `imageGeneration(_:)` / `imageGenerationStream(_:)` | ✅ |
| POST /videos (202 job) · GET /videos/{id} · GET /videos/{id}/content | `videoGeneration(_:)` / `video(jobId:)` / `pollVideo(jobId:)` / `videoContent(jobId:)` | ✅ |
| POST /audio/speech (raw bytes) | `audioSpeech(_:)` | ✅ |
| POST /audio/transcriptions (JSON + multipart) | `audioTranscription(_:)` / `audioTranscription(fileData:...)` | ✅ |

### Presets

| Endpoint | Swift | Status |
|---|---|---|
| GET /presets · /presets/{slug} · versions | `presets()` / `preset(slug:)` / `presetVersions(slug:)` / `presetVersion(slug:version:)` | ✅ |
| POST /presets/{slug}/chat/completions, /messages, /responses (creates/updates the preset — does **not** run inference) | `savePreset(slug:fromChatCompletion:)` / `…fromMessages:` / `…fromResponses:` | ✅ |

### Discovery

| Endpoint | Swift | Status |
|---|---|---|
| GET /models (full filter/sort surface) | `models(filter:)` | ✅ |
| GET /model/{author}/{slug} | `model(author:slug:)` | ✅ |
| GET /models/{author}/{slug}/endpoints | `modelEndpoints(author:slug:)` | ✅ |
| GET /models/count | `modelsCount()` | ✅ |
| GET /models/user | `userModels()` | ✅ |
| GET /embeddings/models | `embeddingsModels()` | ✅ |
| GET /images/models (+ endpoints) · /videos/models | `imagesModels()` / `imageModelEndpoints(author:slug:)` / `videosModels()` | ✅ |
| GET /providers | `providers()` | ✅ |
| GET /endpoints/zdr | `zdrEndpoints()` | ✅ |
| GET /benchmarks · /classifications/task | `benchmarks()` / `taskClassifications()` | ✅ |
| GET /datasets/app-rankings · rankings-daily · session-cost | `appRankings(...)` / `rankingsDaily(...)` / `sessionCosts(...)` | ✅ |

### Observability & account

| Endpoint | Swift | Status |
|---|---|---|
| GET /generation?id= | `generation(id:)` | ✅ |
| GET /generation/content · POST /generation/feedback | `generationContent(id:)` / `submitGenerationFeedback(generationId:category:comment:)` | ✅ |
| GET /key | `keyInfo()` | ✅ |
| GET /credits | `credits()` | ✅ |
| GET /activity · GET /analytics/meta · POST /analytics/query | `activity(filter:)` / `analyticsMeta()` / `analyticsQuery(_:)` | ✅ |
| OAuth PKCE: /auth → POST /auth/keys | `OpenRouterOAuth` (PKCE, `authorizationURL`, `exchangeCode`) | ✅ |
| GET/POST /files · GET/DELETE /files/{id} · content | `files(limit:cursor:)` / `uploadFile(data:filename:mimeType:)` / `file(id:)` / `deleteFile(id:)` / `fileContent(id:)` | ✅ |

### Management **[mgmt]**

| Endpoint | Swift | Status |
|---|---|---|
| /keys CRUD (provisioning; plaintext key returned once) | `keys(...)` / `createKey(_:)` / `key(hash:)` / `updateKey(hash:_:)` / `deleteKey(hash:)` | ✅ |
| /byok CRUD (PATCH `key` rotates in place) | `byokCredentials(...)` / `createByokCredential(_:)` / `updateByokCredential(id:_:)` / `deleteByokCredential(id:)` | ✅ |
| /guardrails CRUD + key/member assignments (removal via POST …/remove) | `guardrails(...)` / `createGuardrail(_:)` / `assignGuardrailKeys(id:keyHashes:)` / … | ✅ |
| /workspaces CRUD + budgets (PUT/{interval}) + members | `workspaces(...)` / `setWorkspaceBudget(id:interval:limitUSD:)` / `addWorkspaceMembers(id:userIds:)` / … | ✅ |
| GET /organization/members | `organizationMembers(offset:limit:)` | ✅ |
| /observability/destinations CRUD | `observabilityDestinations()` / `createObservabilityDestination(_:)` / … | ✅ |
| /scim/groups (read-only) · /scim/group-mappings CRUD | `scimGroups(...)` / `scimGroupMappings(...)` / `createScimGroupMapping(...)` / … | ✅ |

## Errors

All failures throw `OpenRouterError`, mapping OpenRouter's HTTP semantics:

```swift
do {
  _ = try await service.chatCompletion(request)
} catch OpenRouterError.insufficientCredits(let message) {          // 402
} catch OpenRouterError.guardrailViolation(let message, let meta) { // 403
} catch OpenRouterError.rateLimited(let message, let retryAfter) {  // 429 + Retry-After
} catch OpenRouterError.streamError(let code, let message, _) {     // mid-stream, HTTP 200
} catch { }
```

## Design notes (for implementers)

- OpenRouter naming always wins; zero SwiftOpenAI types in the public API (except the
  `OpenRouterHTTPClient` injection typealias).
- Every request type carries an `extraBody` deep-merge escape hatch.
- Streaming handles OpenRouter's SSE specifics: `: OPENROUTER PROCESSING` keep-alives,
  mid-stream error events under HTTP 200, usage on the final chunk, cancellation on task
  cancel.
- Full details and the add-an-endpoint checklist: [INSTRUCTIONS.md](INSTRUCTIONS.md).
