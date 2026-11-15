import SwiftUI
import TypleCore

/// The characters to type, coloured by what has been typed (src/components/Practice/TargetText.tsx): green when
/// done, a caret under the next one, red from the first mistake, and grey for the rest.
struct TargetTextView: View {
  var comparison: InputComparison
  var size: CGFloat

  var body: some View {
    // Each character is its own view so the caret and error backgrounds sit exactly as on the web.
    FlowLayout(spacing: 0, lineSpacing: size * 0.15) {
      ForEach(comparison.characters.indices, id: \.self) { index in
        character(comparison.characters[index], comparison.states[index])
      }
      ForEach(comparison.extra.indices, id: \.self) { index in
        Text(comparison.extra[index])
          .strikethrough()
          .foregroundStyle(Palette.destructive)
          .background(Palette.destructiveSoft, in: RoundedRectangle(cornerRadius: 3))
      }
    }
    .font(.system(size: size, weight: .medium))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(comparison.characters.joined())
  }

  @ViewBuilder
  private func character(_ text: String, _ state: CharacterState) -> some View {
    switch state {
    case .done: Text(text).foregroundStyle(Palette.success)
    case .pending: Text(text).foregroundStyle(Palette.pending)
    case .error:
      Text(text).foregroundStyle(Palette.destructive).background(Palette.destructiveSoft, in: RoundedRectangle(cornerRadius: 3))
    case .current, .currentError:
      Text(text)
        .foregroundStyle(state == .current ? Palette.foreground : Palette.pending)
        .overlay(alignment: .bottom) {
          Capsule().fill(state == .current ? Palette.foreground : Palette.destructive)
            .frame(height: max(3, size * 0.06))
            .offset(y: size * 0.08)
            .modifier(Blink())
        }
    }
  }
}

/// The caret's slow pulse, unless Reduce Motion is on.
private struct Blink: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var dim = false
  func body(content: Content) -> some View {
    content
      .opacity(dim ? 0.4 : 1)
      .onAppear {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { dim = true }
      }
  }
}
