import XCTest
@testable import TypleCore

// The draftProblems case of tests/wordDraft.test.cjs, and what the editors rely on around it.
final class WordDraftTests: XCTestCase {
  private func word(_ display: String, _ input: String = "") -> Word { Word(display: display, input: input) }

  func testListsTheNameFirstThenOneProblemPerWord() {
    let problems = draftProblems(name: " ", words: [("a", word(" ")), ("b", word("ls", "  ")), ("c", word("ls"))])
    XCTAssertEqual(problems, [.name, .display("a"), .input("b")])
  }

  func testAWordWithAnEmptyDisplayIsOnlyADisplayProblem() {
    // The display is checked first; an input of only whitespace is not counted again.
    XCTAssertEqual(draftProblems(name: "list", words: [(1, word("", " "))]), [.display(1)])
  }

  func testAnEmptyInputMeansTheDisplayAndIsNoProblem() {
    XCTAssertEqual(draftProblems(name: "list", words: [(1, word("ls"))]), [])
  }

  func testNewlinesCountAsWhitespace() {
    XCTAssertEqual(draftProblems(name: "\n", words: [(1, word("\t\n")), (2, word("ls", "\n"))]), [.name, .display(1), .input(2)])
  }

  func testWhitespaceAroundAWordIsKept() {
    // Only blank fields are problems: a word may start or end with a space that is meant to be typed.
    XCTAssertEqual(draftProblems(name: " list ", words: [(1, word(" ls ", " -la"))]), [])
  }
}
