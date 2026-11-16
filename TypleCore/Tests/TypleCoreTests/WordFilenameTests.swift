import XCTest
@testable import TypleCore

// The filename cases of tests/exportWords.test.cjs, and how they meet Swift strings.
final class WordFilenameTests: XCTestCase {
  func testRetainsReadableNamesAndRemovesPathAndReservedCharacters() {
    XCTAssertEqual(wordFilename("中国語", format: .csv), "中国語.csv")
    XCTAssertEqual(wordFilename("../a:b\\c?", format: .csv), "_a_b_c_.csv")
    XCTAssertEqual(wordFilename("...", format: .csv), "word-list.csv")
    XCTAssertEqual(wordFilename("CON", format: .csv), "_CON.csv")
    XCTAssertEqual(wordFilename(String(repeating: "a", count: 200), format: .csv).count, 84)
    XCTAssertEqual(wordFilename("中国語", format: .tsv), "中国語.tsv")
  }

  func testReplacesEachUnsafeCharacterAndControlCharacter() {
    XCTAssertEqual(wordFilename("a<>\"|*b", format: .csv), "a_____b.csv")
    XCTAssertEqual(wordFilename("line\nbreak\ttab", format: .csv), "line_break_tab.csv")
    // A percent sign is fine in a file name, as in the web app.
    XCTAssertEqual(wordFilename("100%", format: .csv), "100%.csv")
  }

  func testTrimsDotsAndSpacesAtTheEndsOnly() {
    XCTAssertEqual(wordFilename(" . my list . ", format: .csv), "my list.csv")
    XCTAssertEqual(wordFilename("", format: .csv), "word-list.csv")
    // A name cut at 80 does not end in a dot or a space either.
    XCTAssertEqual(wordFilename(String(repeating: "a", count: 79) + " b", format: .csv), String(repeating: "a", count: 79) + ".csv")
  }

  func testPrefixesReservedDeviceNamesInAnyCase() {
    XCTAssertEqual(wordFilename("nul", format: .csv), "_nul.csv")
    XCTAssertEqual(wordFilename("Com1.txt", format: .csv), "_Com1.txt.csv")
    XCTAssertEqual(wordFilename("console", format: .csv), "console.csv")
  }

  func testCountsEightyLikeJavaScriptAndKeepsWholeCharacters() {
    // The limit is in UTF-16 units, as JavaScript's slice; an emoji that would be cut in two is left out.
    XCTAssertEqual(wordFilename(String(repeating: "😀", count: 50), format: .csv), String(repeating: "😀", count: 40) + ".csv")
    XCTAssertEqual(wordFilename("a" + String(repeating: "😀", count: 50), format: .csv), "a" + String(repeating: "😀", count: 39) + ".csv")
  }
}
