import Foundation

// src/core/writing.ts: Typle Handwriting, where each word's `display` is copied by hand and judged a word at a time.

/// The language a list marked for handwriting is recognized in (WRITING_LANGUAGES in src/core/wordLists.ts).
public enum WritingLanguage: String, Codable, CaseIterable, Sendable {
  case en, ja, zhHans = "zh-Hans", zhHant = "zh-Hant", ko, fr, de, es, ru, cs
}

private let spaceless: Set<WritingLanguage> = [.ja, .zhHans, .zhHant]

/// NFC, trimmed, runs of white space as one space; none at all for languages that are written without spaces.
public func normalizeWriting(_ text: String, language: WritingLanguage) -> String {
  let composed = text.precomposedStringWithCanonicalMapping
  var parts: [String] = []
  var current = ""
  for scalar in composed.unicodeScalars {
    if scalar.properties.isWhitespace {
      if !current.isEmpty { parts.append(current) }
      current = ""
    } else {
      current.unicodeScalars.append(scalar)
    }
  }
  if !current.isEmpty { parts.append(current) }
  return parts.joined(separator: spaceless.contains(language) ? "" : " ")
}

/// Reads the candidate from the front, one target character at a time; the whole candidate has to be used.
private func matchesOne(_ candidate: [String], _ target: [String], options: TypingOptions) -> Bool {
  var p = 0
  let fold = { (value: String) in options.ignoreCase ? value.lowercased() : value }
  let same = { (a: String, b: String) in fold(a).unicodeScalars.elementsEqual(fold(b).unicodeScalars) }
  let slice = { (count: Int) in candidate[min(p, candidate.count)..<min(p + count, candidate.count)].joined() }
  for t in target {
    if p < candidate.count && matchesCharacter(candidate[p], t, options: options) {
      p += 1
      continue
    }
    guard options.ignoreAccents else { return false }
    if t == "ß" || t == "ẞ" {
      guard same(slice(2), t == "ß" ? "ss" : "SS") else { return false }
      p += 2
      continue
    }
    guard let alternative = cyrillicAlternatives(options.ignoreCase ? t.lowercased() : t)
      .first(where: { same(slice($0.unicodeScalars.count), $0) }) else { return false }
    p += alternative.unicodeScalars.count
  }
  return p == candidate.count
}

public func matchesWriting(_ candidates: [String], target: String, language: WritingLanguage,
                           options: TypingOptions = TypingOptions()) -> Bool {
  let expected = normalizeWriting(target, language: language).codePoints.map { String($0) }
  return candidates.contains { candidate in
    matchesOne(normalizeWriting(candidate, language: language).codePoints.map { String($0) }, expected, options: options)
  }
}

/// Runs the clock: starts it on the first call and carries on after a pause.
public func startWriting(_ session: TypingSession, now: Double) -> TypingSession {
  guard session.finishedAt == nil else { return session }
  var resumed = resumeSession(session, now: now)
  if resumed.startedAt == nil { resumed.startedAt = now }
  return resumed
}

private func advance(_ session: TypingSession, words: [Word], now: Double) -> TypingSession {
  var next = session
  if session.index >= words.count - 1 {
    next.finishedAt = now
  } else {
    next.index += 1
    next.input = ""
  }
  return next
}

/// A match moves on. A mismatch counts only when the writer asked for it (explicit, e.g. Return) and wrote something;
/// a silent recognition result that does not match yet changes nothing.
public func judgeWriting(_ session: TypingSession, words: [Word], candidates: [String], now: Double,
                         language: WritingLanguage, options: TypingOptions, explicit: Bool) -> TypingSession {
  guard session.finishedAt == nil, session.index < words.count else { return session }
  if matchesWriting(candidates, target: words[session.index].display, language: language, options: options) {
    var started = startWriting(session, now: now)
    started.attempts += 1
    started.missed = false
    return advance(started, words: words, now: now)
  }
  guard explicit, candidates.contains(where: { !normalizeWriting($0, language: language).isEmpty }) else { return session }
  var started = startWriting(session, now: now)
  started.attempts += 1
  started.mistakes += 1
  started.missed = true
  return started
}

public func skipWord(_ session: TypingSession, words: [Word], now: Double) -> TypingSession {
  guard session.finishedAt == nil, session.index < words.count else { return session }
  var started = startWriting(session, now: now)
  started.attempts += 1
  started.mistakes += 1
  started.missed = false
  return advance(started, words: words, now: now)
}
