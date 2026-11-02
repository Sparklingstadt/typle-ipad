import Foundation
import Observation
import TypleCore

enum SaveState {
  case idle, saving, saved, failed
}

/// One practice run (src/lib/usePractice.ts): the session, the device it started on and saving its record.
@MainActor
@Observable
final class PracticeModel {
  private(set) var listId: String? = nil
  private(set) var session = TypingSession()
  /// The device chosen when the run started; changing the choice mid-run does not change the record.
  private(set) var practiceDevice: PracticeDevice? = nil
  /// Whether an input method is composing text in the field.
  private(set) var composing = false
  private(set) var record: StoredRecord? = nil
  private(set) var saveState = SaveState.idle
  var focusRequest = 0
  /// How this run is practised; it stays for the run even if the list's mark is taken off meanwhile.
  private(set) var mode = PracticeMode.normal
  /// The language a Handwriting run is read in, taken from the list when the run starts.
  private(set) var language = WritingLanguage.en
  /// What the last check of a Handwriting word read, shown until the word is judged again or another starts.
  private(set) var writingFeedback: WritingFeedback? = nil

  enum WritingFeedback: Equatable {
    case read(String)
    case unreadable
  }

  var finished: Bool { session.finishedAt != nil }
  var started: Bool { session.startedAt != nil }
  var running: Bool { started && !finished }

  func list(in lists: [WordList]) -> WordList? {
    lists.first { $0.id == listId } ?? lists.first
  }

  /// Starts again, on another list and in another mode when given.
  func restart(listId: String? = nil, mode: PracticeMode? = nil, language: WritingLanguage? = nil) {
    if let listId { self.listId = listId }
    if let mode { self.mode = mode }
    if let language { self.language = language }
    session = TypingSession()
    writingFeedback = nil
    practiceDevice = nil
    composing = false
    record = nil
    saveState = .idle
    focusRequest += 1
  }

  /// Shows the list without starting a run, keeping a run already in progress on it.
  func select(_ id: String?) {
    if id != listId { listId = id }
  }

  func setComposing(_ value: Bool) { composing = value }

  func enter(_ value: String, list: WordList, device: PracticeDevice?, app: AppModel) {
    guard record == nil else { return }
    let now = (Date().timeIntervalSince1970 * 1000).rounded()
    let next = typeInput(session, words: list.words, value: value, now: now)
    if session.startedAt == nil && next.startedAt != nil { practiceDevice = device }
    listId = list.id
    session = next
    guard next.finishedAt != nil, let record = try? makeRecord(next, wordCount: list.words.count, id: randomId(), device: practiceDevice) else { return }
    self.record = record
    save(record, listId: list.id, app: app)
  }

  // MARK: Handwriting

  private var now: Double { (Date().timeIntervalSince1970 * 1000).rounded() }

  /// Runs the clock from the first stroke, on the device chosen then.
  func beginWriting(device: PracticeDevice?) {
    guard record == nil, !finished else { return }
    if session.startedAt == nil { practiceDevice = device }
    session = startWriting(session, now: now)
  }

  /// Judges what was written. A silent check (after a pause in writing, or as the field changes) only moves on.
  func judge(_ candidates: [String], list: WordList, explicit: Bool, device: PracticeDevice?, app: AppModel) {
    guard record == nil, !finished else { return }
    if session.startedAt == nil { practiceDevice = device }
    let index = session.index
    let next = judgeWriting(session, words: list.words, candidates: candidates, now: now, language: language,
                            options: TypingOptions(), explicit: explicit)
    if next.index != index || next.finishedAt != nil {
      writingFeedback = nil
    } else if explicit {
      let read = candidates.first { !normalizeWriting($0, language: language).isEmpty }
      writingFeedback = read.map { .read($0) } ?? .unreadable
    }
    finish(next, list: list, app: app)
  }

  func skip(list: WordList, device: PracticeDevice?, app: AppModel) {
    guard record == nil, !finished else { return }
    if session.startedAt == nil { practiceDevice = device }
    writingFeedback = nil
    finish(skipWord(session, words: list.words, now: now), list: list, app: app)
  }

  /// Stops the clock while the app is in the background or the field has lost focus.
  func pause() {
    session = pauseSession(session, now: now)
  }

  private func finish(_ next: TypingSession, list: WordList, app: AppModel) {
    listId = list.id
    session = next
    guard next.finishedAt != nil,
          let record = try? makeRecord(next, wordCount: list.words.count, id: randomId(), device: practiceDevice, mode: mode) else { return }
    self.record = record
    save(record, listId: list.id, app: app)
  }

  func retrySave(app: AppModel) {
    guard let record, let listId else { return }
    save(record, listId: listId, app: app)
  }

  private func save(_ record: StoredRecord, listId: String, app: AppModel) {
    saveState = .saving
    Task {
      do {
        try await app.addRecord(record, listId: listId)
        if self.record == record { saveState = .saved }
      } catch {
        if self.record == record { saveState = .failed }
      }
    }
  }
}
