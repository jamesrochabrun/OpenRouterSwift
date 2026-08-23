import XCTest
@testable import OpenRouterSwift

final class MediaFilesTests: XCTestCase {
  private var mock: MockHTTPClient!
  private var service: OpenRouterService!

  override func setUp() {
    super.setUp()
    mock = MockHTTPClient()
    service = OpenRouter.service(apiKey: "sk-or-test", httpClient: mock)
  }

  func testImageGeneration() async throws {
    let pixel = Data([0x89, 0x50, 0x4E, 0x47]).base64EncodedString()
    mock.enqueueJSON("""
      {"created": 1756000000,
       "data": [{"b64_json": "\(pixel)", "media_type": "image/png"}],
       "usage": {"total_tokens": 100, "cost": 0.01}}
      """)

    let response = try await service.imageGeneration(
      ImageGenerationRequest(
        model: "google/gemini-2.5-flash-image",
        prompt: "a cat",
        aspectRatio: "1:1",
        n: 1,
        outputFormat: "png",
        quality: "high"))

    let request = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(request.url.absoluteString, "https://openrouter.ai/api/v1/images")
    let body = try bodyJSON(request)
    XCTAssertEqual(body["prompt"] as? String, "a cat")
    XCTAssertEqual(body["aspect_ratio"] as? String, "1:1")
    XCTAssertEqual(body["output_format"] as? String, "png")

    XCTAssertEqual(response.data.first?.mediaType, "image/png")
    XCTAssertEqual(response.data.first?.imageData?.count, 4)
    XCTAssertEqual(response.usage?.cost, 0.01)
  }

  func testVideoJobLifecyclePaths() async throws {
    mock.enqueueJSON(
      #"{"id": "job_1", "status": "pending", "polling_url": "https://openrouter.ai/api/v1/videos/job_1"}"#,
      statusCode: 202)
    let job = try await service.videoGeneration(
      VideoGenerationRequest(model: "some/video-model", prompt: "waves", duration: 5))
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/videos")
    XCTAssertEqual(job.status, .pending)
    XCTAssertFalse(job.isTerminal)

    mock.enqueueJSON(
      #"{"id": "job_1", "status": "completed", "polling_url": "u", "generation_id": "gen_9", "usage": {"cost": 0.5}}"#)
    let done = try await service.video(jobId: "job_1")
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/videos/job_1")
    XCTAssertTrue(done.isTerminal)
    XCTAssertEqual(done.usage?.cost, 0.5)

    mock.enqueue(.data(Data([0x00, 0x01, 0x02]), statusCode: 200))
    let bytes = try await service.videoContent(jobId: "job_1", index: 1)
    XCTAssertEqual(
      mock.lastRequest?.url.absoluteString,
      "https://openrouter.ai/api/v1/videos/job_1/content?index=1")
    XCTAssertEqual(bytes.count, 3)
  }

  func testAudioSpeechReturnsRawBytes() async throws {
    mock.enqueue(.data(Data([0xFF, 0xFB, 0x90]), statusCode: 200))
    let audio = try await service.audioSpeech(
      AudioSpeechRequest(model: "some/tts", input: "Hello", voice: "alloy", responseFormat: .mp3))
    XCTAssertEqual(mock.lastRequest?.url.absoluteString, "https://openrouter.ai/api/v1/audio/speech")
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual(body["input"] as? String, "Hello")
    XCTAssertEqual(body["response_format"] as? String, "mp3")
    XCTAssertEqual(audio.count, 3)
  }

  func testAudioTranscriptionJSONMode() async throws {
    mock.enqueueJSON(
      #"{"text": "Hello world", "language": "en", "duration": 1.5, "usage": {"cost": 0.0001, "seconds": 1.5}}"#)
    let result = try await service.audioTranscription(
      AudioTranscriptionRequest(
        model: "openai/whisper-large",
        inputAudio: .init(data: "QUJD", format: "wav"),
        language: "en"))
    let body = try bodyJSON(mock.lastRequest)
    XCTAssertEqual((body["input_audio"] as? [String: Any])?["format"] as? String, "wav")
    XCTAssertEqual(result.text, "Hello world")
    XCTAssertEqual(result.usage?.seconds, 1.5)
  }

  func testAudioTranscriptionMultipartMode() async throws {
    mock.enqueueJSON(#"{"text": "Multipart works"}"#)
    let result = try await service.audioTranscription(
      fileData: Data("RIFF".utf8),
      filename: "clip.wav",
      model: "openai/whisper-large",
      language: nil,
      responseFormat: .verboseJson,
      temperature: nil,
      timestampGranularities: ["word"])

    let request = try XCTUnwrap(mock.lastRequest)
    let contentType = try XCTUnwrap(request.headers["Content-Type"])
    XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="))
    let bodyText = String(decoding: try XCTUnwrap(request.body), as: UTF8.self)
    XCTAssertTrue(bodyText.contains("name=\"file\"; filename=\"clip.wav\""))
    XCTAssertTrue(bodyText.contains("name=\"model\""))
    XCTAssertTrue(bodyText.contains("verbose_json"))
    XCTAssertTrue(bodyText.contains("name=\"timestamp_granularities[]\""))
    XCTAssertEqual(result.text, "Multipart works")
  }

  func testFilesLifecycle() async throws {
    mock.enqueueJSON("""
      {"data": [{"id": "f_1", "filename": "doc.pdf", "mime_type": "application/pdf",
                 "size_bytes": 1234, "downloadable": true, "type": "file"}],
       "has_more": false}
      """)
    let list = try await service.files(limit: 10, cursor: nil)
    XCTAssertEqual(list.data.first?.sizeBytes, 1234)

    mock.enqueueJSON(#"{"id": "f_2", "filename": "up.txt", "mime_type": "text/plain", "size_bytes": 3, "type": "file"}"#)
    let uploaded = try await service.uploadFile(data: Data("abc".utf8), filename: "up.txt", mimeType: "text/plain")
    let uploadRequest = try XCTUnwrap(mock.lastRequest)
    XCTAssertEqual(uploadRequest.method.rawValue, "POST")
    XCTAssertTrue((uploadRequest.headers["Content-Type"] ?? "").hasPrefix("multipart/form-data"))
    XCTAssertEqual(uploaded.id, "f_2")

    mock.enqueueJSON(#"{"id": "f_2", "type": "file_deleted"}"#)
    let deleted = try await service.deleteFile(id: "f_2")
    XCTAssertEqual(mock.lastRequest?.method.rawValue, "DELETE")
    XCTAssertEqual(deleted.type, "file_deleted")
  }
}
