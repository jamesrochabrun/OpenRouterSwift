import Foundation

/// Everything an OpenRouter **inference key** can do.
///
/// Method names and shapes mirror OpenRouter's API — see the endpoint mapping table in the
/// README. Management-key endpoints live on `OpenRouterManagementService`.
public protocol OpenRouterService: Sendable {

  // MARK: Chat completions

  /// `POST /api/v1/chat/completions`
  func chatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse

  /// `POST /api/v1/chat/completions` with `stream: true` (set automatically).
  /// The final chunk carries `usage`. Cancel the surrounding `Task` to abort the generation.
  func chatCompletionStream(_ request: ChatCompletionRequest)
    async throws -> AsyncThrowingStream<ChatCompletionChunk, Error>

  // MARK: Messages (Anthropic format)

  /// `POST /api/v1/messages`
  func message(_ request: MessagesRequest) async throws -> MessagesResponse

  /// `POST /api/v1/messages` with `stream: true` (set automatically).
  func messageStream(_ request: MessagesRequest)
    async throws -> AsyncThrowingStream<MessagesStreamEvent, Error>

  // MARK: Responses (OpenResponses)

  /// `POST /api/v1/responses`
  func response(_ request: ResponsesRequest) async throws -> ResponsesResponse

  /// `POST /api/v1/responses` with `stream: true` (set automatically).
  func responseStream(_ request: ResponsesRequest)
    async throws -> AsyncThrowingStream<ResponsesStreamEvent, Error>

  // MARK: Embeddings

  /// `POST /api/v1/embeddings`
  func embeddings(_ request: EmbeddingsRequest) async throws -> EmbeddingsResponse

  /// `GET /api/v1/embeddings/models`
  func embeddingsModels() async throws -> [OpenRouterModel]

  // MARK: Rerank

  /// `POST /api/v1/rerank`
  func rerank(_ request: RerankRequest) async throws -> RerankResponse

  // MARK: Presets

  /// `GET /api/v1/presets`
  func presets(offset: Int?, limit: Int?) async throws -> PresetList

  /// `GET /api/v1/presets/{slug}`
  func preset(slug: String) async throws -> PresetDetail

  /// `GET /api/v1/presets/{slug}/versions`
  func presetVersions(slug: String, offset: Int?, limit: Int?) async throws -> PresetVersionList

  /// `GET /api/v1/presets/{slug}/versions/{version}`
  func presetVersion(slug: String, version: String) async throws -> PresetVersion

  /// `POST /api/v1/presets/{slug}/chat/completions` — creates a preset (or a new version of
  /// an existing one) from a chat request body. Only config-overlapping fields are persisted;
  /// `messages`/`stream` are ignored. **Does not run inference** — invoke a preset by using
  /// `model: "@preset/slug"` in a normal request. Requires a management key.
  func savePreset(slug: String, fromChatCompletion request: ChatCompletionRequest) async throws -> PresetDetail

  /// `POST /api/v1/presets/{slug}/messages` — like `savePreset(slug:fromChatCompletion:)`
  /// but persisting from an Anthropic-format request body.
  func savePreset(slug: String, fromMessages request: MessagesRequest) async throws -> PresetDetail

  /// `POST /api/v1/presets/{slug}/responses` — like `savePreset(slug:fromChatCompletion:)`
  /// but persisting from a Responses request body.
  func savePreset(slug: String, fromResponses request: ResponsesRequest) async throws -> PresetDetail

  // MARK: Models & discovery

  /// `GET /api/v1/models`
  func models(filter: ModelsFilter?) async throws -> [OpenRouterModel]

  /// `GET /api/v1/model/{author}/{slug}`
  func model(author: String, slug: String) async throws -> OpenRouterModel

  /// `GET /api/v1/models/{author}/{slug}/endpoints`
  func modelEndpoints(author: String, slug: String) async throws -> ModelEndpointsList

  /// `GET /api/v1/models/count`
  func modelsCount() async throws -> Int

  /// `GET /api/v1/models/user` — models available to this key, after applying its
  /// provider preferences, privacy settings, and guardrails.
  func userModels() async throws -> [OpenRouterModel]

  // MARK: Account

  /// `GET /api/v1/key` — info about the calling key (limits, usage, tier).
  func keyInfo() async throws -> KeyInfo

  /// `GET /api/v1/credits`
  func credits() async throws -> Credits

  // MARK: Images

  /// `POST /api/v1/images`
  func imageGeneration(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse

  /// `POST /api/v1/images` with `stream: true` (set automatically).
  func imageGenerationStream(_ request: ImageGenerationRequest)
    async throws -> AsyncThrowingStream<ImageStreamEvent, Error>

  /// `GET /api/v1/images/models`
  func imagesModels() async throws -> [ImageModel]

  /// `GET /api/v1/images/models/{author}/{slug}/endpoints`
  func imageModelEndpoints(author: String, slug: String) async throws -> ImageModelEndpointsList

  // MARK: Videos (async jobs)

  /// `POST /api/v1/videos` — returns 202 with a job; poll with `video(jobId:)`.
  func videoGeneration(_ request: VideoGenerationRequest) async throws -> VideoJob

  /// `GET /api/v1/videos/{jobId}`
  func video(jobId: String) async throws -> VideoJob

  /// `GET /api/v1/videos/{jobId}/content` — raw video bytes (`video/mp4`).
  func videoContent(jobId: String, index: Int?) async throws -> Data

  /// `GET /api/v1/videos/models`
  func videosModels() async throws -> [VideoModel]

  // MARK: Audio

  /// `POST /api/v1/audio/speech` — returns raw audio bytes (mp3 or pcm).
  func audioSpeech(_ request: AudioSpeechRequest) async throws -> Data

  /// `POST /api/v1/audio/transcriptions` (JSON mode, base64 audio).
  func audioTranscription(_ request: AudioTranscriptionRequest) async throws -> AudioTranscription

  /// `POST /api/v1/audio/transcriptions` (multipart file upload).
  func audioTranscription(
    fileData: Data,
    filename: String,
    model: String,
    language: String?,
    responseFormat: AudioTranscriptionRequest.ResponseFormat?,
    temperature: Double?,
    timestampGranularities: [String]?)
    async throws -> AudioTranscription

  // MARK: Files

  /// `GET /api/v1/files`
  func files(limit: Int?, cursor: String?) async throws -> FileList

  /// `POST /api/v1/files` — multipart upload (≤100 MB).
  func uploadFile(data: Data, filename: String, mimeType: String) async throws -> FileObject

  /// `GET /api/v1/files/{file_id}`
  func file(id: String) async throws -> FileObject

  /// `DELETE /api/v1/files/{file_id}`
  func deleteFile(id: String) async throws -> FileDeleted

  /// `GET /api/v1/files/{file_id}/content` — raw bytes (server-generated files only).
  func fileContent(id: String) async throws -> Data

  // MARK: Generation stats

  /// `GET /api/v1/generation?id=` — authoritative post-hoc cost and native token counts.
  func generation(id: String) async throws -> Generation

  /// `GET /api/v1/generation/content?id=` — the stored input/output of a generation.
  func generationContent(id: String) async throws -> GenerationContent

  /// `POST /api/v1/generation/feedback` — returns whether the feedback was recorded.
  func submitGenerationFeedback(
    generationId: String,
    category: GenerationFeedbackCategory,
    comment: String?)
    async throws -> Bool

  // MARK: Activity & analytics

  /// `GET /api/v1/activity` — 30-day usage rows.
  func activity(filter: ActivityFilter?) async throws -> [ActivityRow]

  /// `GET /api/v1/analytics/meta`
  func analyticsMeta() async throws -> AnalyticsMeta

  /// `POST /api/v1/analytics/query`
  func analyticsQuery(_ request: AnalyticsQueryRequest) async throws -> AnalyticsQueryResult

  // MARK: Ecosystem data

  /// `GET /api/v1/providers`
  func providers() async throws -> [Provider]

  /// `GET /api/v1/endpoints/zdr` — all zero-data-retention endpoints.
  func zdrEndpoints() async throws -> [ZDREndpoint]

  /// `GET /api/v1/benchmarks`
  func benchmarks() async throws -> BenchmarksResponse

  /// `GET /api/v1/classifications/task`
  func taskClassifications() async throws -> TaskClassifications

  /// `GET /api/v1/datasets/app-rankings`
  func appRankings(category: String?, sort: String?, limit: Int?) async throws -> [AppRanking]

  /// `GET /api/v1/datasets/rankings-daily`
  func rankingsDaily(startDate: String?, endDate: String?, category: String?) async throws -> [DailyRanking]

  /// `GET /api/v1/datasets/session-cost`
  func sessionCosts(appSlug: String?, model: String?, limit: Int?) async throws -> [SessionCost]
}

extension OpenRouterService {
  /// `GET /api/v1/models` with no filters.
  public func models() async throws -> [OpenRouterModel] {
    try await models(filter: nil)
  }

  /// `GET /api/v1/presets` with default paging.
  public func presets() async throws -> PresetList {
    try await presets(offset: nil, limit: nil)
  }

  /// `GET /api/v1/presets/{slug}/versions` with default paging.
  public func presetVersions(slug: String) async throws -> PresetVersionList {
    try await presetVersions(slug: slug, offset: nil, limit: nil)
  }

  /// `GET /api/v1/videos/{jobId}/content` for the first output.
  public func videoContent(jobId: String) async throws -> Data {
    try await videoContent(jobId: jobId, index: nil)
  }

  /// Polls `video(jobId:)` until the job reaches a terminal state.
  /// - Parameters:
  ///   - interval: seconds between polls (default 5).
  ///   - timeout: give up after this many seconds (default 600).
  public func pollVideo(
    jobId: String,
    interval: TimeInterval = 5,
    timeout: TimeInterval = 600)
    async throws -> VideoJob
  {
    let deadline = Date().addingTimeInterval(timeout)
    while true {
      let job = try await video(jobId: jobId)
      if job.isTerminal {
        return job
      }
      if Date() >= deadline {
        return job
      }
      try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
  }

  /// `GET /api/v1/files` with default paging.
  public func files() async throws -> FileList {
    try await files(limit: nil, cursor: nil)
  }

  /// `GET /api/v1/activity` with no filters.
  public func activity() async throws -> [ActivityRow] {
    try await activity(filter: nil)
  }
}
