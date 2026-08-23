import XCTest
@testable import OpenRouterSwift

final class SSEParserTests: XCTestCase {
  func testCommentKeepAliveIsSkipped() {
    XCTAssertEqual(SSEParser.parse(line: ": OPENROUTER PROCESSING"), .comment)
  }

  func testDoneSentinel() {
    XCTAssertEqual(SSEParser.parse(line: "data: [DONE]"), .done)
  }

  func testDataPayload() {
    XCTAssertEqual(SSEParser.parse(line: "data: {\"id\":\"gen-1\"}"), .data("{\"id\":\"gen-1\"}"))
  }

  func testDataPayloadWithoutSpace() {
    XCTAssertEqual(SSEParser.parse(line: "data:{\"id\":\"gen-1\"}"), .data("{\"id\":\"gen-1\"}"))
  }

  func testEventLine() {
    XCTAssertEqual(SSEParser.parse(line: "event: response.output_text.delta"), .event("response.output_text.delta"))
  }

  func testBlankLineIgnored() {
    XCTAssertEqual(SSEParser.parse(line: ""), .ignore)
    XCTAssertEqual(SSEParser.parse(line: "   "), .ignore)
  }
}
