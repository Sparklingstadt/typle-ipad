import SwiftUI
import TypleCore

/// One word of a typing run: the word to type, coloured by what has been typed, and the field it is typed in.
struct TypingPracticeView: View {
  @Environment(AppModel.self) private var app
  var list: WordList
  var model: PracticeModel
  @Binding var inputFocused: Bool
  /// Whether the field has had focus in this visit: the resume button shows only after that.
  @Binding var focusedOnce: Bool
  /// A sheet or a confirmation is over the card, which has the focus for now.
  var paused: Bool
  /// Esc in the field: starts again in the mode the list has now.
  var onRestart: () -> Void

  var body: some View {
    let words = list.words
    let session = model.session
    let word = words[min(session.index, words.count - 1)]
    let comparison = compareInput(target: word.input, typed: session.input)
    let showResume = focusedOnce && !inputFocused && !paused
    VStack(spacing: 0) {
      VStack(spacing: 14) {
        if !word.annotation.isEmpty {
          Text(word.annotation).font(.system(size: 16)).multilineTextAlignment(.center)
        }
        if word.display == word.input {
          TargetTextView(comparison: comparison, size: practiceWordSize(word.display))
        } else {
          Text(word.display).font(.system(size: practiceWordSize(word.display), weight: .medium)).multilineTextAlignment(.center)
          HStack(spacing: 10) {
            Text(L("practice.word.typeThis")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
              .padding(.horizontal, 8).frame(height: 22).overlay(Capsule().strokeBorder(Palette.border))
            TargetTextView(comparison: comparison, size: 30).fixedSize()
          }
        }
      }
      .frame(maxWidth: .infinity, minHeight: 208)
      .padding(.horizontal, 24)
      .padding(.top, 32)
      .overlay {
        if showResume { resumeButton }
      }
      VStack(spacing: 10) {
        let invalid = comparison.errorIndex != nil
        PracticeTextField(
          text: session.input, placeholder: L("practice.word.placeholder"),
          focusRequest: model.focusRequest,
          onCommit: { value in
            guard let current = model.list(in: app.lists) else { return }
            model.enter(value, list: current, device: app.chosenPracticeDevice, app: app)
          },
          onComposingChange: { model.setComposing($0) },
          onFocusChange: { focused in
            inputFocused = focused
            if focused { focusedOnce = true }
          },
          onEscape: onRestart)
          .frame(height: 56)
          .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.lg))
          .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(invalid ? Palette.destructive : inputFocused ? Palette.primary : Palette.input, lineWidth: 2))
          .overlay(
            RoundedRectangle(cornerRadius: Radius.lg + 4)
              .strokeBorder(invalid ? Palette.destructive.opacity(0.2) : Palette.ring.opacity(inputFocused ? 0.35 : 0), lineWidth: 4)
              .padding(-4)
          )
          .frame(maxWidth: 440)
        feedback(comparison)
      }
      .padding(.horizontal, 24)
      .padding(.top, 8)
      .padding(.bottom, 20)
    }
  }

  private var resumeButton: some View {
    Button { model.focusRequest += 1 } label: {
      Label(L("practice.word.resume"), systemImage: Platform.resumeIcon)
        .font(.system(size: 14, weight: .medium))
        .labelStyle(TightLabelStyle())
        .foregroundStyle(Palette.primaryForeground)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(Palette.primary, in: Capsule())
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.card.opacity(0.7))
    .background(.ultraThinMaterial)
  }

  private func feedback(_ comparison: InputComparison) -> some View {
    Group {
      if let errorIndex = comparison.errorIndex {
        Label(L("practice.feedback.mismatch", errorIndex + 1), systemImage: "exclamationmark.circle")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(Palette.destructive)
      } else if model.composing {
        Text(L("practice.feedback.composing"))
      } else {
        HStack(spacing: 16) {
          HStack(spacing: 6) { Kbd(text: "Backspace"); Text(L("practice.feedback.backspace")) }
          HStack(spacing: 6) { Kbd(text: "Esc"); Text(L("practice.feedback.restart")) }
        }
      }
    }
    .labelStyle(TightLabelStyle())
    .font(.system(size: 12))
    .foregroundStyle(Palette.mutedForeground)
    .frame(minHeight: 20)
    .accessibilityAddTraits(.updatesFrequently)
  }
}

/// The size of the word to type or copy: shorter text gets the large size; anything over 24 characters gets a
/// paragraph size.
func practiceWordSize(_ text: String) -> CGFloat {
  let length = text.unicodeScalars.count
  if length > 24 { return 26 }
  return length > 10 ? 44 : 64
}
