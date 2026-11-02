import Foundation
import XCTest
@testable import TypleCore

// The list mark `writing` and the record `mode` as src/core/wordLists.ts and src/core/records.ts read and keep them.
final class WritingDataTests: XCTestCase {
  private func file(list: String = #""writing":{"language":"zh-Hans"}"#, record: String = #""mode":"writing""#) -> Data {
    Data(#"{"version":1,"accountId":"g","revision":1,"devices":[],"lists":[{"id":"l","name":"L",\#(list),"words":[{"display":"爱护","input":"aihu","annotation":""}],"records":[{"id":"r","time":1,"date":"2026-11-02T00:00:00.000Z","accuracy":100,"mistakes":0,"wordCount":1,\#(record)}],"createdAt":"2026-11-02T00:00:00.000Z"}]}"#.utf8)
  }

  private func errorKey(_ body: () throws -> Any) -> String? {
    do { _ = try body(); return nil } catch let error as TypleError { return error.key } catch { return "\(error)" }
  }

  func testWritingMarkRoundTrips() throws {
    let decoded = try decodeWorkspaceFile(file(), accountId: "g")
    XCTAssertEqual(decoded.lists[0].writing, WritingMark(language: .zhHans))
    let again = try decodeWorkspaceFile(try encodeWorkspaceFile(decoded), accountId: "g")
    XCTAssertEqual(again, decoded)
    let unmarked = WordList(id: "x", name: "X", words: [Word(display: "a", input: "a")], createdAt: "2026-11-02T00:00:00.000Z")
    XCTAssertFalse(String(decoding: try JSONEncoder().encode(unmarked), as: UTF8.self).contains("writing"))
  }

  func testWritingMarkRefusesExtraKeysAndUnknownLanguages() {
    for mark in [#""writing":{"language":"xx"}"#, #""writing":{"language":"en","x":1}"#, #""writing":{}"#, #""writing":null"#] {
      XCTAssertEqual(errorKey { try decodeWorkspaceFile(file(list: mark), accountId: "g") }, "savedDataUnreadable", mark)
    }
  }

  func testWritingModeRoundTrips() throws {
    let decoded = try decodeWorkspaceFile(file(), accountId: "g")
    XCTAssertEqual(decoded.lists[0].records[0].mode, "writing")
    XCTAssertTrue(String(decoding: try encodeWorkspaceFile(decoded), as: UTF8.self).contains(#""mode":"writing""#))
  }

  func testNullModeIsRefused() {
    XCTAssertEqual(errorKey { try decodeWorkspaceFile(file(record: #""mode":null"#), accountId: "g") }, "savedDataUnreadable")
  }

  func testUnknownModeIsRefused() {
    XCTAssertEqual(errorKey { try decodeWorkspaceFile(file(record: #""mode":"x""#), accountId: "g") }, "savedDataCorrupted")
  }

  func testDuplicateKeepsWritingMark() throws {
    let list = try decodeWorkspaceFile(file(), accountId: "g").lists
    let copy = try duplicateList(list, id: "l", copyId: "c", suffix: { "（コピー\($0)）" }).copy
    XCTAssertEqual(copy.writing, WritingMark(language: .zhHans))
  }

  func testSaveListKeepsWritingMark() throws {
    var lists = try decodeWorkspaceFile(file(), accountId: "g").lists
    var edited = lists[0]
    edited.writing = WritingMark(language: .ja)
    lists = try saveList(lists, edited, editing: true)
    XCTAssertEqual(lists[0].writing, WritingMark(language: .ja))
    edited.writing = nil
    XCTAssertNil(try saveList(lists, edited, editing: true)[0].writing)
  }
}
