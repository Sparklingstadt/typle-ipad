import XCTest
@testable import TypleCore

// matchesName: the search of the rankings and the list picker, which look at names only.
final class ListSearchTests: XCTestCase {
  private let list = WordList(id: "a", name: "macOS ターミナル", words: [Word(display: "ls", input: "ls")], createdAt: "2026-11-01T00:00:00.000Z")

  func testABlankQueryMatchesEveryList() {
    XCTAssertTrue(matchesName(list, ""))
    XCTAssertTrue(matchesName(list, "   "))
  }

  func testMatchesPartOfTheNameIgnoringCaseAndSurroundingSpaces() {
    XCTAssertTrue(matchesName(list, "MACOS"))
    XCTAssertTrue(matchesName(list, "  ターミナル "))
    XCTAssertFalse(matchesName(list, "linux"))
  }

  func testLooksAtTheNameOnlyUnlikeMatchesQuery() {
    XCTAssertFalse(matchesName(list, "ls"))
    XCTAssertTrue(matchesQuery(list, "ls"))
  }
}
