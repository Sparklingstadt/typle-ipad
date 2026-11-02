import Foundation

/// One run through a list (src/core/typing.ts). Times are milliseconds since 1970.
public struct TypingSession: Equatable, Sendable {
  public var index = 0
  public var input = ""
  public var startedAt: Double?
  public var finishedAt: Double?
  public var attempts = 0
  public var mistakes = 0
  /// When the practice was paused mid-run; the clock stands still until it is resumed. Typing does not use it yet.
  public var pausedAt: Double?
  /// The last check did not match (handwriting); cleared when the word is judged again or another starts.
  public var missed = false

  public init() {}
}

/// Stops the clock of a running session. Before the first character or after the last there is nothing to stop.
public func pauseSession(_ session: TypingSession, now: Double) -> TypingSession {
  guard session.startedAt != nil, session.finishedAt == nil, session.pausedAt == nil else { return session }
  var paused = session
  paused.pausedAt = now
  return paused
}

/// Moves startedAt on by the length of the pause, so elapsed time, speed and the recorded time all leave it out.
public func resumeSession(_ session: TypingSession, now: Double) -> TypingSession {
  guard let pausedAt = session.pausedAt, let startedAt = session.startedAt else { return session }
  var resumed = session
  resumed.startedAt = startedAt + max(0, now - pausedAt)
  resumed.pausedAt = nil
  return resumed
}

/// Milliseconds of practice so far: up to the finish, or to the pause while paused.
public func elapsedTime(_ session: TypingSession, now: Double) -> Double {
  guard let startedAt = session.startedAt else { return 0 }
  return max(0, (session.finishedAt ?? session.pausedAt ?? now) - startedAt)
}

public struct TypingOptions: Equatable, Sendable {
  /// Simple input: plain Latin letters for accents and Cyrillic, ss for ß, and ? for ¿.
  public var ignoreAccents: Bool
  /// Upper and lower case count as the same letter (a for A, É for é).
  public var ignoreCase: Bool

  public init(ignoreAccents: Bool = false, ignoreCase: Bool = false) {
    self.ignoreAccents = ignoreAccents
    self.ignoreCase = ignoreCase
  }
}

/// The blocks of Unicode's Latin script, for `\p{Script=Latin}`, which Swift has no property for.
private let latinRanges: [ClosedRange<UInt32>] = [
  0x41...0x5A, 0x61...0x7A, 0xAA...0xAA, 0xBA...0xBA, 0xC0...0xD6, 0xD8...0xF6, 0xF8...0x24F, 0x250...0x2AF,
  0x1D00...0x1D7F, 0x1E00...0x1EFF, 0x2C60...0x2C7F, 0xA720...0xA7FF, 0xAB30...0xAB6F, 0xFF21...0xFF3A, 0xFF41...0xFF5A,
]

/// A Latin letter with its accents and other marks taken off, or nil for anything else. Only Latin letters are folded:
/// kana such as が also split into a base and a mark, and か must not count for it.
public func latinBase(_ char: String) -> String? {
  let base = char.decomposedStringWithCanonicalMapping.unicodeScalars.filter { scalar in
    ![.nonspacingMark, .spacingMark, .enclosingMark].contains(scalar.properties.generalCategory)
  }
  guard base.count == 1, let scalar = base.first, latinRanges.contains(where: { $0.contains(scalar.value) }) else { return nil }
  return String(scalar)
}

public let cyrillicLatin: [String: String] = [
  "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "yo", "ж": "zh", "з": "z",
  "и": "i", "й": "y", "к": "k", "л": "l", "м": "m", "н": "n", "о": "o", "п": "p", "р": "r",
  "с": "s", "т": "t", "у": "u", "ф": "f", "х": "kh", "ц": "ts", "ч": "ch", "ш": "sh", "щ": "shch",
  "ъ": "\"", "ы": "y", "ь": "'", "э": "e", "ю": "yu", "я": "ya",
]

public func cyrillicAlternatives(_ target: String) -> [String] {
  let lower = target.lowercased()
  guard let latin = cyrillicLatin[lower] else { return [] }
  // Capital letters accept title case (Sh) and all caps (SH).
  return target == lower ? [latin] : [latin.prefix(1).uppercased() + latin.dropFirst(), latin.uppercased()]
}

public func matchesCharacter(_ typed: String, _ target: String, options: TypingOptions = TypingOptions()) -> Bool {
  let typed = options.ignoreCase ? typed.lowercased() : typed
  let target = options.ignoreCase ? target.lowercased() : target
  if typed.unicodeScalars.elementsEqual(target.unicodeScalars) { return true }
  guard options.ignoreAccents else { return false }
  if target == "¿" && typed == "?" { return true }
  if cyrillicAlternatives(target).contains(where: { $0.unicodeScalars.elementsEqual(typed.unicodeScalars) }) { return true }
  return latinBase(target).map { $0.unicodeScalars.elementsEqual(typed.unicodeScalars) } ?? false
}

/// Applies the input field's new value. Only characters added since the last value count as attempts, and an added
/// character is a mistake when it differs from the character at its position.
public func typeInput(_ session: TypingSession, words: [Word], value: String, now: Double) -> TypingSession {
  guard session.finishedAt == nil, session.index < words.count else { return session }
  let target = words[session.index].input.codePoints
  let previous = session.input.codePoints
  let next = value.codePoints
  var common = 0
  while common < previous.count && common < next.count && previous[common] == next[common] { common += 1 }
  let inserted = next[common...]
  var updated = session
  updated.input = value
  updated.startedAt = session.startedAt ?? (value.isEmpty ? nil : now)
  updated.attempts += inserted.count
  updated.mistakes += inserted.enumerated().filter { offset, char in
    let index = common + offset
    return index >= target.count || char != target[index]
  }.count
  // Compared by code point, as JavaScript does, so composed and decomposed forms stay different.
  guard next == target else { return updated }
  if session.index == words.count - 1 {
    updated.finishedAt = now
    return updated
  }
  updated.index += 1
  updated.input = ""
  return updated
}

public struct SessionResult: Equatable, Sendable {
  public var time: Double
  public var mistakes: Int
  public var accuracy: Double
}

public func sessionResult(_ session: TypingSession) -> SessionResult {
  let accuracy = session.attempts > 0
    ? (Double(session.attempts - session.mistakes) / Double(session.attempts) * 10000).rounded() / 100 : 100
  return SessionResult(time: max(0, ((session.finishedAt ?? 0) - (session.startedAt ?? 0)) / 1000),
                       mistakes: session.mistakes, accuracy: accuracy)
}

public enum CharacterState: Sendable {
  case done, current, error, currentError, pending
}

public struct InputComparison: Equatable, Sendable {
  public var characters: [String]
  public var states: [CharacterState]
  public var extra: [String]
  /// The first wrong position, or nil when everything typed so far is right.
  public var errorIndex: Int?
}

/// Compares only committed input with the characters to type. Everything from the first mismatch on is an error,
/// so a later character that happens to match is not shown as correct.
public func compareInput(target: String, typed: String) -> InputComparison {
  let characters = target.codePoints
  let actual = typed.codePoints
  var errorIndex = actual.indices.first { $0 < characters.count && actual[$0] != characters[$0] }
  if errorIndex == nil && actual.count > characters.count { errorIndex = characters.count }
  let states = characters.indices.map { index -> CharacterState in
    if index < actual.count { return errorIndex == nil || index < errorIndex! ? .done : .error }
    if index == actual.count { return errorIndex == nil ? .current : .currentError }
    return .pending
  }
  return InputComparison(characters: characters.map { String($0) }, states: states,
                         extra: actual.dropFirst(characters.count).map { String($0) }, errorIndex: errorIndex)
}

/// Correctly typed characters per minute; nil until a second has passed.
public func typingSpeed(_ session: TypingSession, now: Double) -> Int? {
  guard let startedAt = session.startedAt else { return nil }
  let elapsed = (session.finishedAt ?? now) - startedAt
  return elapsed < 1000 ? nil : Int((Double(session.attempts - session.mistakes) / (elapsed / 60000)).rounded())
}
