import XCTest
@testable import TypleCore

// The compareRun case of tests/records.test.cjs.
final class CompareRunTests: XCTestCase {
  private func run(_ id: String, _ time: Double, wordCount: Int = 2, mode: String? = nil) -> StoredRecord {
    StoredRecord(id: id, time: time, date: "2026-09-01T00:00:00Z", accuracy: 100, wordCount: wordCount, mode: mode)
  }

  func testRanksASavedRunAmongRunsOfItsModeAtTheSameWordCount() {
    let record = run("new", 3)
    XCTAssertEqual(compareRun(record, [record], wordCount: 2, saved: true, mode: .normal), RunComparison(rank: 1, kind: .firstForList))
    XCTAssertEqual(compareRun(record, [record, run("old", 5, wordCount: 3)], wordCount: 2, saved: true, mode: .normal),
                   RunComparison(rank: 1, kind: .firstAtCount))
    XCTAssertEqual(compareRun(record, [record, run("old", 5)], wordCount: 2, saved: true, mode: .normal),
                   RunComparison(rank: 1, kind: .best(difference: -2)))
    let faster = run("old", 1)
    XCTAssertEqual(compareRun(record, [record, faster], wordCount: 2, saved: true, mode: .normal),
                   RunComparison(rank: 2, kind: .behind(previous: faster)))
  }

  func testAnUnsavedRunHasNoRankSoIsNeverTheBest() {
    let record = run("new", 3)
    XCTAssertEqual(compareRun(record, [record, run("old", 5)], wordCount: 2, saved: false, mode: .normal),
                   RunComparison(rank: 0, kind: .behind(previous: run("old", 5))))
  }

  func testARecallRunIsNeverComparedWithNormalRuns() {
    let record = run("new", 3)
    XCTAssertEqual(compareRun(record, [record, run("recall", 1, mode: "recall")], wordCount: 2, saved: true, mode: .normal),
                   RunComparison(rank: 1, kind: .firstForList))
  }

  func testWithoutARunItComparesTheListsRuns() {
    // Before a run is made (or when it could not be made), the list's own runs decide the note.
    XCTAssertEqual(compareRun(nil, [], wordCount: 2, saved: false, mode: .normal), RunComparison(rank: 0, kind: .firstForList))
    let old = run("old", 5)
    XCTAssertEqual(compareRun(nil, [old], wordCount: 2, saved: false, mode: .normal), RunComparison(rank: 0, kind: .behind(previous: old)))
  }
}
