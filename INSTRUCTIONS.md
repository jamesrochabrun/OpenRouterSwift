# OpenRouterSwift — Contributor & Agent Instructions

Single source of truth for working on this package. `CLAUDE.md` and `AGENTS.md` are symlinks
to this file — edit only `INSTRUCTIONS.md`.

## What this package is

A Swift client that makes **OpenRouter a first-class citizen**: the public API mirrors
OpenRouter's endpoints, naming, and request/response shapes exactly — never OpenAI's or any
other provider's. SwiftOpenAI (SPM dependency, same author) provides only the cross-platform
HTTP transport.

Spec source of truth: **https://openrouter.ai/openapi.yaml** (verify shapes there before
implementing; docs at https://openrouter.ai/docs).

## Non-negotiable invariants

1. **OpenRouter naming always wins.** Types, properties, and method names follow OpenRouter's
   API (`ChatCompletionRequest`, `provider`, `min_p` → `minP`), not SwiftOpenAI's.
2. **No SwiftOpenAI types in the public API** — the single deliberate exception is the
   `OpenRouterHTTPClient` typealias (the injection point for custom transports). Everything
   else from SwiftOpenAI is an implementation detail so the dependency can be narrowed or
   dropped without breaking consumers.
3. **Every request type has an `extraBody: [String: JSONValue]?` escape hatch**, deep-merged
   into the top-level JSON at encode time (typed fields win on collision). This package must
   never repeat SwiftOpenAI's fixed-CodingKeys limitation.
4. **Explicit `CodingKeys` everywhere.** Never use `.convertToSnakeCase`/`.convertFromSnakeCase`
   — they mangle dictionary keys (`logit_bias` token ids, metadata blobs).
5. Response-model fields are **optional and lenient** (except true invariants like `id`) so
   provider variance never crashes decoding. Unknown/unstable shapes decode as `JSONValue`.
6. All public models are `Sendable`. Services are protocols (`OpenRouterService`,
   `OpenRouterManagementService`) so consumers can mock them.

## Code style

- 2-space indent, spaces not tabs.
- Modern concurrency only: `async/await`, `AsyncThrowingStream`. No callbacks.
- Public structs: `public var` fields + memberwise `public init` with `= nil` defaults.
- Request types are `Encodable`-only; response types `Decodable`-only. `Codable` only when a
  type genuinely appears in both directions (e.g. `ToolCall`, `CacheControl`).
- Doc comment on every public symbol; endpoint methods state their route, e.g.
  `` /// `POST /api/v1/chat/completions` ``.

## Architecture map

```
OpenRouter.service(apiKey:configuration:httpClient:)   // factory (OpenRouter.swift)
  └─ DefaultOpenRouterService: OpenRouterService        // Service/
       └─ OpenRouterTransport                           // Networking/ — fetch / fetchData / fetchStream
            ├─ OpenRouterAPI                            // endpoint enum → path + HTTP method
            ├─ SSEParser                                // pure line → event (comments, [DONE], data)
            └─ SwiftOpenAI.HTTPClient                   // the ONLY SwiftOpenAI surface we use
```

- `OpenRouterTransport.mapError` maps HTTP semantics: 402 `insufficientCredits`,
  403 `guardrailViolation`, 429 `rateLimited` (+`Retry-After`), 524 `providerTimeout`,
  529 `serviceOverloaded`, else `.api`.
- Two service tiers mirror OpenRouter's key classes: `OpenRouterService` (inference keys) and
  `OpenRouterManagementService` (management keys — provisioning, workspaces, guardrails, BYOK,
  SCIM). Never add a management endpoint to the inference protocol.

## SSE gotchas (already handled in `OpenRouterTransport.fetchStream` — don't regress)

- Comment lines (`: OPENROUTER PROCESSING`) are keep-alives → skip.
- Mid-stream errors arrive as `data:` events containing a top-level `error` object **under
  HTTP 200** → throw `OpenRouterError.streamError`.
- The final chunk before `data: [DONE]` carries `usage` (with USD `cost`).
- `continuation.onTermination` cancels the underlying task → aborts the connection, which
  stops billing on providers that support cancellation.

## How to add an endpoint (checklist)

1. Verify the shape in https://openrouter.ai/openapi.yaml.
2. Add a case to `Networking/OpenRouterAPI.swift` (path + method).
3. Add request/response models under `Models/<Family>/` (explicit CodingKeys, `extraBody` on
   requests, lenient optionals on responses).
4. Add the method to the right protocol (`OpenRouterService` or `OpenRouterManagementService`)
   with a route doc comment, and implement it in the `Default…` class.
5. Add tests in `Tests/OpenRouterSwiftTests/`: assert URL path, method, headers, and encoded
   body via `bodyJSON(_:)` dictionary comparison; decode a fixture lifted from the openapi
   spec. Streaming endpoints: fixture must include comment lines and a mid-stream error case.
6. Update the endpoint table in `README.md` (flip ⬜ → ✅, fill in the Swift method column).
7. `swift build && swift test` must pass.

## Deprecated OpenRouter surface — do NOT implement

- `POST /completions` (legacy text completions) — removed from the spec.
- `transforms: ["middle-out"]` → use the `context-compression` plugin.
- `route: "fallback"` → use `provider` preferences.
- `usage: {include: true}` / `stream_options.include_usage` — no-ops; usage is always returned.
- `POST /credits/coinbase`.

## Testing conventions

- `MockHTTPClient` (in `Tests/.../Mocks/`) scripts responses and records `HTTPRequest`s.
- Never compare JSON as strings — decode with `JSONSerialization` and compare values.
- No network in unit tests. Manual smoke tests live in `Examples/` and need
  `OPENROUTER_API_KEY`.

## Dependency note

`Package.swift` currently uses a **local path dependency** on `../SwiftOpenAI` because the
public `HTTPRequest`/`HTTPResponse` fields and `HTTPMethod.patch/.put` cases are not yet in a
tagged SwiftOpenAI release. Once tagged upstream, switch to
`.package(url: "https://github.com/jamesrochabrun/SwiftOpenAI", from: "<that version>")`.

## Phase status

- [x] Phase 0 — skeleton: transport, SSE, errors, JSONValue, mocks, docs
- [x] Phase 1 (v0.1.0) — chat completions + streaming, models discovery, key, credits, generation
- [x] OAuth PKCE helper (`OpenRouterOAuth`) — pulled forward from Phase 4
- [x] Phase 2 (v0.2.0) — /messages (Anthropic shape), /responses (stateless), presets, embeddings, rerank
- [x] Phase 3 (v0.3.0) — images (+streaming), videos (async jobs + pollVideo), audio speech/transcription (JSON + multipart), files
- [x] Phase 4 (v0.4.0) — generation content/feedback, activity, analytics, providers, ZDR, benchmarks, classifications, datasets
- [x] Phase 5 (v0.5.0) — management tier: keys provisioning, BYOK, guardrails (+assignments), workspaces (+budgets/members), org members, observability destinations
- [x] Phase 6 — SCIM groups/group-mappings
- [ ] v1.0.0 polish — DocC catalog, CI (macOS + Linux matrix), live smoke tests in Examples/, API stability audit
