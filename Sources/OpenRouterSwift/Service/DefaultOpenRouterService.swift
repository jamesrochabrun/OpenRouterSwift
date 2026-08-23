import Foundation
import SwiftOpenAI

/// Default `OpenRouterService` implementation over `OpenRouterTransport`.
/// Create instances via `OpenRouter.service(apiKey:...)`.
final class DefaultOpenRouterService: OpenRouterService, @unchecked Sendable {
  private let transport: OpenRouterTransport

  init(transport: OpenRouterTransport) {
    self.transport = transport
  }

  // MARK: Chat completions

  func chatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
    var request = request
    request.stream = nil
    return try await transport.fetch(.chatCompletions, body: request)
  }

  func chatCompletionStream(_ request: ChatCompletionRequest)
    async throws -> AsyncThrowingStream<ChatCompletionChunk, Error>
  {
    var request = request
    request.stream = true
    return try await transport.fetchStream(.chatCompletions, body: request)
  }

  // MARK: Messages (Anthropic format)

  func message(_ request: MessagesRequest) async throws -> MessagesResponse {
    var request = request
    request.stream = nil
    return try await transport.fetch(.messages, body: request)
  }

  func messageStream(_ request: MessagesRequest)
    async throws -> AsyncThrowingStream<MessagesStreamEvent, Error>
  {
    var request = request
    request.stream = true
    return try await transport.fetchStream(.messages, body: request)
  }

  // MARK: Responses (OpenResponses)

  func response(_ request: ResponsesRequest) async throws -> ResponsesResponse {
    var request = request
    request.stream = nil
    return try await transport.fetch(.responses, body: request)
  }

  func responseStream(_ request: ResponsesRequest)
    async throws -> AsyncThrowingStream<ResponsesStreamEvent, Error>
  {
    var request = request
    request.stream = true
    return try await transport.fetchStream(.responses, body: request)
  }

  // MARK: Embeddings

  func embeddings(_ request: EmbeddingsRequest) async throws -> EmbeddingsResponse {
    try await transport.fetch(.embeddings, body: request)
  }

  func embeddingsModels() async throws -> [OpenRouterModel] {
    let response: ModelsResponse = try await transport.fetch(.embeddingsModels)
    return response.data
  }

  // MARK: Rerank

  func rerank(_ request: RerankRequest) async throws -> RerankResponse {
    try await transport.fetch(.rerank, body: request)
  }

  // MARK: Presets

  private func pagingItems(offset: Int?, limit: Int?) -> [URLQueryItem] {
    var items = [URLQueryItem]()
    if let offset {
      items.append(URLQueryItem(name: "offset", value: String(offset)))
    }
    if let limit {
      items.append(URLQueryItem(name: "limit", value: String(limit)))
    }
    return items
  }

  func presets(offset: Int?, limit: Int?) async throws -> PresetList {
    try await transport.fetch(.presets, queryItems: pagingItems(offset: offset, limit: limit))
  }

  func preset(slug: String) async throws -> PresetDetail {
    let response: PresetDetailResponse = try await transport.fetch(.preset(slug: slug))
    return response.data
  }

  func presetVersions(slug: String, offset: Int?, limit: Int?) async throws -> PresetVersionList {
    try await transport.fetch(
      .presetVersions(slug: slug),
      queryItems: pagingItems(offset: offset, limit: limit))
  }

  func presetVersion(slug: String, version: String) async throws -> PresetVersion {
    let response: PresetVersionResponse = try await transport.fetch(
      .presetVersion(slug: slug, version: version))
    return response.data
  }

  func savePreset(slug: String, fromChatCompletion request: ChatCompletionRequest) async throws -> PresetDetail {
    let response: PresetDetailResponse = try await transport.fetch(
      .presetChatCompletions(slug: slug),
      body: request)
    return response.data
  }

  func savePreset(slug: String, fromMessages request: MessagesRequest) async throws -> PresetDetail {
    let response: PresetDetailResponse = try await transport.fetch(
      .presetMessages(slug: slug),
      body: request)
    return response.data
  }

  func savePreset(slug: String, fromResponses request: ResponsesRequest) async throws -> PresetDetail {
    let response: PresetDetailResponse = try await transport.fetch(
      .presetResponses(slug: slug),
      body: request)
    return response.data
  }

  // MARK: Models & discovery

  func models(filter: ModelsFilter?) async throws -> [OpenRouterModel] {
    let response: ModelsResponse = try await transport.fetch(
      .models,
      queryItems: filter?.queryItems ?? [])
    return response.data
  }

  func model(author: String, slug: String) async throws -> OpenRouterModel {
    let response: SingleModelResponse = try await transport.fetch(.model(author: author, slug: slug))
    return response.data
  }

  func modelEndpoints(author: String, slug: String) async throws -> ModelEndpointsList {
    let response: ModelEndpointsResponse = try await transport.fetch(
      .modelEndpoints(author: author, slug: slug))
    return response.data
  }

  func modelsCount() async throws -> Int {
    let response: ModelsCountResponse = try await transport.fetch(.modelsCount)
    return response.data.count
  }

  func userModels() async throws -> [OpenRouterModel] {
    let response: ModelsResponse = try await transport.fetch(.modelsUser)
    return response.data
  }

  // MARK: Account

  func keyInfo() async throws -> KeyInfo {
    let response: KeyInfoResponse = try await transport.fetch(.key)
    return response.data
  }

  func credits() async throws -> Credits {
    let response: CreditsResponse = try await transport.fetch(.credits)
    return response.data
  }

  // MARK: Images

  func imageGeneration(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
    var request = request
    request.stream = nil
    return try await transport.fetch(.images, body: request)
  }

  func imageGenerationStream(_ request: ImageGenerationRequest)
    async throws -> AsyncThrowingStream<ImageStreamEvent, Error>
  {
    var request = request
    request.stream = true
    return try await transport.fetchStream(.images, body: request)
  }

  func imagesModels() async throws -> [ImageModel] {
    let response: ImageModelsResponse = try await transport.fetch(.imagesModels)
    return response.data
  }

  func imageModelEndpoints(author: String, slug: String) async throws -> ImageModelEndpointsList {
    try await transport.fetch(.imageModelEndpoints(author: author, slug: slug))
  }

  // MARK: Videos

  func videoGeneration(_ request: VideoGenerationRequest) async throws -> VideoJob {
    try await transport.fetch(.videos, body: request)
  }

  func video(jobId: String) async throws -> VideoJob {
    try await transport.fetch(.video(jobId: jobId))
  }

  func videoContent(jobId: String, index: Int?) async throws -> Data {
    var queryItems = [URLQueryItem]()
    if let index {
      queryItems.append(URLQueryItem(name: "index", value: String(index)))
    }
    return try await transport.fetchData(.videoContent(jobId: jobId), queryItems: queryItems)
  }

  func videosModels() async throws -> [VideoModel] {
    let response: VideoModelsResponse = try await transport.fetch(.videosModels)
    return response.data
  }

  // MARK: Audio

  func audioSpeech(_ request: AudioSpeechRequest) async throws -> Data {
    try await transport.fetchData(.audioSpeech, body: request)
  }

  func audioTranscription(_ request: AudioTranscriptionRequest) async throws -> AudioTranscription {
    try await transport.fetch(.audioTranscriptions, body: request)
  }

  func audioTranscription(
    fileData: Data,
    filename: String,
    model: String,
    language: String?,
    responseFormat: AudioTranscriptionRequest.ResponseFormat?,
    temperature: Double?,
    timestampGranularities: [String]?)
    async throws -> AudioTranscription
  {
    var form = MultipartFormData()
    form.addFile(name: "file", filename: filename, mimeType: "application/octet-stream", data: fileData)
    form.addField(name: "model", value: model)
    if let language {
      form.addField(name: "language", value: language)
    }
    if let responseFormat {
      form.addField(name: "response_format", value: responseFormat.rawValue)
    }
    if let temperature {
      form.addField(name: "temperature", value: String(temperature))
    }
    for granularity in timestampGranularities ?? [] {
      form.addField(name: "timestamp_granularities[]", value: granularity)
    }
    let request = try transport.rawRequest(
      .audioTranscriptions,
      body: form.encoded(),
      contentType: form.contentType)
    return try await transport.fetch(request: request)
  }

  // MARK: Files

  func files(limit: Int?, cursor: String?) async throws -> FileList {
    var queryItems = [URLQueryItem]()
    if let limit {
      queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
    }
    if let cursor {
      queryItems.append(URLQueryItem(name: "cursor", value: cursor))
    }
    return try await transport.fetch(.files, queryItems: queryItems)
  }

  func uploadFile(data: Data, filename: String, mimeType: String) async throws -> FileObject {
    var form = MultipartFormData()
    form.addFile(name: "file", filename: filename, mimeType: mimeType, data: data)
    let request = try transport.rawRequest(
      .files,
      body: form.encoded(),
      contentType: form.contentType)
    var mutableRequest = request
    mutableRequest.method = .post
    return try await transport.fetch(request: mutableRequest)
  }

  func file(id: String) async throws -> FileObject {
    try await transport.fetch(.file(id: id))
  }

  func deleteFile(id: String) async throws -> FileDeleted {
    try await transport.fetch(.file(id: id), method: .delete)
  }

  func fileContent(id: String) async throws -> Data {
    try await transport.fetchData(.fileContent(id: id))
  }

  // MARK: Generation stats

  func generation(id: String) async throws -> Generation {
    let response: GenerationResponse = try await transport.fetch(
      .generation,
      queryItems: [URLQueryItem(name: "id", value: id)])
    return response.data
  }

  func generationContent(id: String) async throws -> GenerationContent {
    let response: GenerationContentResponse = try await transport.fetch(
      .generationContent,
      queryItems: [URLQueryItem(name: "id", value: id)])
    return response.data
  }

  func submitGenerationFeedback(
    generationId: String,
    category: GenerationFeedbackCategory,
    comment: String?)
    async throws -> Bool
  {
    let response: GenerationFeedbackResponse = try await transport.fetch(
      .generationFeedback,
      body: GenerationFeedbackRequest(generationId: generationId, category: category, comment: comment))
    return response.data.success
  }

  // MARK: Activity & analytics

  func activity(filter: ActivityFilter?) async throws -> [ActivityRow] {
    let response: ActivityResponse = try await transport.fetch(
      .activity,
      queryItems: filter?.queryItems ?? [])
    return response.data
  }

  func analyticsMeta() async throws -> AnalyticsMeta {
    let response: AnalyticsMetaResponse = try await transport.fetch(.analyticsMeta)
    return response.data
  }

  func analyticsQuery(_ request: AnalyticsQueryRequest) async throws -> AnalyticsQueryResult {
    try await transport.fetch(.analyticsQuery, body: request)
  }

  // MARK: Ecosystem data

  func providers() async throws -> [Provider] {
    let response: ProvidersResponse = try await transport.fetch(.providers)
    return response.data
  }

  func zdrEndpoints() async throws -> [ZDREndpoint] {
    let response: ZDREndpointsResponse = try await transport.fetch(.endpointsZDR)
    return response.data
  }

  func benchmarks() async throws -> BenchmarksResponse {
    try await transport.fetch(.benchmarks)
  }

  func taskClassifications() async throws -> TaskClassifications {
    let response: TaskClassificationsResponse = try await transport.fetch(
      .classificationsTask,
      queryItems: [URLQueryItem(name: "window", value: "7d")])
    return response.data
  }

  func appRankings(category: String?, sort: String?, limit: Int?) async throws -> [AppRanking] {
    var queryItems = [URLQueryItem]()
    if let category { queryItems.append(URLQueryItem(name: "category", value: category)) }
    if let sort { queryItems.append(URLQueryItem(name: "sort", value: sort)) }
    if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
    let response: DatasetResponse<AppRanking> = try await transport.fetch(
      .datasetsAppRankings,
      queryItems: queryItems)
    return response.data
  }

  func rankingsDaily(startDate: String?, endDate: String?, category: String?) async throws -> [DailyRanking] {
    var queryItems = [URLQueryItem]()
    if let startDate { queryItems.append(URLQueryItem(name: "start_date", value: startDate)) }
    if let endDate { queryItems.append(URLQueryItem(name: "end_date", value: endDate)) }
    if let category { queryItems.append(URLQueryItem(name: "category", value: category)) }
    let response: DatasetResponse<DailyRanking> = try await transport.fetch(
      .datasetsRankingsDaily,
      queryItems: queryItems)
    return response.data
  }

  func sessionCosts(appSlug: String?, model: String?, limit: Int?) async throws -> [SessionCost] {
    var queryItems = [URLQueryItem]()
    if let appSlug { queryItems.append(URLQueryItem(name: "app_slug", value: appSlug)) }
    if let model { queryItems.append(URLQueryItem(name: "model", value: model)) }
    if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
    let response: DatasetResponse<SessionCost> = try await transport.fetch(
      .datasetsSessionCost,
      queryItems: queryItems)
    return response.data
  }
}
