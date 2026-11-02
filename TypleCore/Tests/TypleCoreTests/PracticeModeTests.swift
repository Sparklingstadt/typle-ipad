import Foundation
import XCTest
@testable import TypleCore

// Normal, recall and writing runs are ranked apart (src/core/records.ts, src/core/rankings.ts).
final class PracticeModeTests: XCTestCase {
  let words = [Word(display: "a", input: "a"), Word(display: "b", input: "b")]

  func list() -> WordList {
    WordList(id: "l", name: "L", words: words, records: [
      StoredRecord(id: "n", time: 9, date: "2026-11-01T00:00:00.000Z", accuracy: 90, wordCount: 2),
      StoredRecord(id: "r", time: 8, date: "2026-11-01T01:00:00.000Z", accuracy: 95, wordCount: 2, mode: "recall"),
      StoredRecord(id: "w", time: 7, date: "2026-11-01T02:00:00.000Z", accuracy: 100, wordCount: 2, mode: "writing"),
    ], createdAt: "2026-11-01T00:00:00.000Z")
  }

  func testRecordMode() {
    XCTAssertEqual(list().records.map(recordMode), [.normal, .recall, .writing])
    XCTAssertEqual(recordsOfMode(list().records, .writing).map(\.id), ["w"])
  }

  func testBestsAreKeptPerMode() {
    XCTAssertEqual(listBest(list())?.id, "n")
    XCTAssertEqual(listBest(list(), mode: .recall)?.id, "r")
    XCTAssertEqual(listBest(list(), mode: .writing)?.id, "w")
    let rows = recordRows([list()])
    XCTAssertEqual(rows.filter(\.best).count, 3)
    XCTAssertEqual(rows.first { $0.record.id == "w" }?.mode, .writing)
  }

  func testRankingOfWriting() {
    XCTAssertEqual(listRanking(list(), mode: .writing).ranked.map(\.id), ["w"])
    XCTAssertEqual(listRanking(list()).ranked.map(\.id), ["n"])
  }

  func testMakeRecordWritesWritingMode() throws {
    var session = TypingSession()
    session.startedAt = 1000
    session.finishedAt = 2000
    session.attempts = 2
    XCTAssertEqual(try makeRecord(session, wordCount: 2, id: "x", device: nil, mode: .writing).mode, "writing")
    XCTAssertNil(try makeRecord(session, wordCount: 2, id: "x", device: nil).mode)
  }

  func testCurrentRecordCountIsNormalOnly() {
    XCTAssertEqual(currentRecordCount(list()), 1)
  }
}
