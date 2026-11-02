import Foundation
import XCTest
@testable import TypleCore

// tests/writing.test.cjs, with the cases of tests/fixtures/writing/match.json that both apps read.
final class WritingTests: XCTestCase {
  private struct Case: Decodable {
    struct Options: Decodable { var ignoreAccents: Bool?; var ignoreCase: Bool? }
    var description: String
    var candidates: [String]
    var target: String
    var language: WritingLanguage
    var options: Options
    var expected: Bool
  }

  func testMatchesWritingFixture() throws {
    let url = try XCTUnwrap(Bundle.module.url(forResource: "match", withExtension: "json", subdirectory: "Fixtures/writing"))
    let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: url))
    XCTAssertFalse(cases.isEmpty)
    for c in cases {
      let options = TypingOptions(ignoreAccents: c.options.ignoreAccents ?? false, ignoreCase: c.options.ignoreCase ?? false)
      XCTAssertEqual(matchesWriting(c.candidates, target: c.target, language: c.language, options: options), c.expected, c.description)
    }
  }

  func testNormalizeWriting() {
    XCTAssertEqual(normalizeWriting("  a   b ", language: .en), "a b")
    XCTAssertEqual(normalizeWriting("e\u{301}", language: .fr), "\u{e9}")
    XCTAssertEqual(normalizeWriting("あ　い う", language: .ja), "あいう")
    XCTAssertEqual(normalizeWriting("한 국", language: .ko), "한 국")
  }

  private let words = [Word(display: "ab", input: "ab"), Word(display: "cd", input: "cd")]

  private func judge(_ s: TypingSession, _ candidates: [String], _ now: Double, _ explicit: Bool) -> TypingSession {
    judgeWriting(s, words: words, candidates: candidates, now: now, language: .en, options: TypingOptions(), explicit: explicit)
  }

  func testCorrectWordAdvances() {
    let s = judge(TypingSession(), ["ab"], 1000, false)
    XCTAssertEqual(s.index, 1)
    XCTAssertEqual(s.attempts, 1)
    XCTAssertEqual(s.mistakes, 0)
    XCTAssertEqual(s.startedAt, 1000)
    XCTAssertNil(s.finishedAt)
  }

  func testLastWordFinishesAndFinishedSessionIsLeftAlone() {
    var s = judge(TypingSession(), ["ab"], 1000, false)
    s = judge(s, ["cd"], 2000, false)
    XCTAssertEqual(s.finishedAt, 2000)
    XCTAssertEqual(judge(s, ["cd"], 3000, true), s)
    XCTAssertEqual(skipWord(s, words: words, now: 3000), s)
    XCTAssertEqual(startWriting(s, now: 3000), s)
  }

  func testExplicitMismatchIsAMistake() {
    let s = judge(TypingSession(), ["xx"], 1000, true)
    XCTAssertEqual(s.index, 0)
    XCTAssertEqual(s.attempts, 1)
    XCTAssertEqual(s.mistakes, 1)
    XCTAssertTrue(s.missed)
    XCTAssertFalse(judge(s, ["ab"], 2000, false).missed)
  }

  func testSilentMismatchChangesNothing() {
    XCTAssertEqual(judge(TypingSession(), ["xx"], 1000, false), TypingSession())
  }

  func testEmptyCheckIsNotAMistake() {
    XCTAssertEqual(judge(TypingSession(), [], 1000, true), TypingSession())
    XCTAssertEqual(judge(TypingSession(), [""], 1000, true), TypingSession())
    XCTAssertEqual(judge(TypingSession(), ["  "], 1000, true), TypingSession())
  }

  func testSkipWordCountsAMistake() {
    var s = skipWord(TypingSession(), words: words, now: 1000)
    XCTAssertEqual(s.index, 1)
    XCTAssertEqual(s.attempts, 1)
    XCTAssertEqual(s.mistakes, 1)
    XCTAssertFalse(s.missed)
    s = skipWord(s, words: words, now: 2000)
    XCTAssertEqual(s.finishedAt, 2000)
    XCTAssertEqual(s.attempts, 2)
  }

  func testStartWritingResumesAPause() {
    var s = startWriting(TypingSession(), now: 1000)
    XCTAssertEqual(s.startedAt, 1000)
    XCTAssertEqual(startWriting(s, now: 1500).startedAt, 1000)
    s = pauseSession(s, now: 2000)
    XCTAssertEqual(elapsedTime(s, now: 9000), 1000)
    s = startWriting(s, now: 5000)
    XCTAssertEqual(s.startedAt, 4000)
    XCTAssertNil(s.pausedAt)
  }

  func testJudgingResumesAPause() {
    var s = pauseSession(startWriting(TypingSession(), now: 1000), now: 2000)
    s = judge(s, ["ab"], 5000, false)
    XCTAssertEqual(s.startedAt, 4000)
    XCTAssertNil(s.pausedAt)
  }

  func testAccuracyOfOneMistakeInTwoWords() {
    var s = judge(TypingSession(), ["xx"], 1000, true)
    s = judge(s, ["ab"], 2000, false)
    s = judge(s, ["cd"], 3000, false)
    XCTAssertEqual(sessionResult(s).accuracy, 66.67)
  }

  func testOneSkipInTwoWordsIsFifty() {
    var s = skipWord(TypingSession(), words: words, now: 1000)
    s = judge(s, ["cd"], 2000, false)
    XCTAssertEqual(sessionResult(s).accuracy, 50)
  }

  func testUnmarkedListIsTyped() {
    let unmarked = WordList(id: "a", name: "A", words: words, createdAt: "x")
    var marked = unmarked
    marked.writing = WritingMark(language: .en)
    XCTAssertEqual(practiceMode(unmarked, writing: true), .normal)
    XCTAssertEqual(practiceMode(marked, writing: true), .writing)
    XCTAssertEqual(practiceMode(marked, writing: false), .normal)
    XCTAssertEqual(practiceMode(nil, writing: true), .normal)
  }

  func testWritingCandidatesJoinsLines() {
    XCTAssertEqual(writingCandidates([["I am", "l am"], ["a student."]]),
                   ["I am", "l am", "a student.", "I ama student.", "I am a student."])
    XCTAssertEqual(writingCandidates([["爱护", "爱护"]]), ["爱护"])
    XCTAssertEqual(writingCandidates([]), [])
  }

  func testStaleRecognitionIsDropped() {
    XCTAssertTrue(isCurrentRecognition(startedAt: (index: 0, generation: 3), now: (index: 0, generation: 3)))
    XCTAssertFalse(isCurrentRecognition(startedAt: (index: 0, generation: 3), now: (index: 0, generation: 4)))
    XCTAssertFalse(isCurrentRecognition(startedAt: (index: 0, generation: 3), now: (index: 1, generation: 3)))
  }
}
