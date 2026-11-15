import Foundation

// src/core/wordDraft.ts

/// What keeps a draft list from being saved (DraftProblem): its name, or a word's display or input, by the key the
/// editor gives each row.
public enum DraftProblem<Key: Hashable>: Hashable {
  case name
  case display(Key)
  case input(Key)
}

/// draftProblems: the name first, then at most one problem per word: a blank display, or else an input of only
/// whitespace. An empty input is no problem, since it means the display; whitespace around a word is kept, since it can
/// be meant to be typed.
public func draftProblems<Key: Hashable>(name: String, words: [(key: Key, word: Word)]) -> [DraftProblem<Key>] {
  var problems: [DraftProblem<Key>] = []
  if name.trimmed.isEmpty { problems.append(.name) }
  for (key, word) in words {
    if word.display.trimmed.isEmpty { problems.append(.display(key)) }
    else if !word.input.isEmpty && word.input.trimmed.isEmpty { problems.append(.input(key)) }
  }
  return problems
}
