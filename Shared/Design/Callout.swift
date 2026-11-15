import SwiftUI

/// The tint of a callout box: why something failed, a caution, or a quiet note.
enum CalloutTone {
  /// A light red box with a red hairline, such as a save that failed.
  case destructive
  /// The amber of a best record, such as a word count that changes which records count.
  case warning
  /// A grey box for a note or a chart, such as a list not yet practised.
  case muted
}

extension View {
  /// A callout box behind the content, with the lg radius. The padding is the caller's.
  @ViewBuilder
  func callout(_ tone: CalloutTone) -> some View {
    switch tone {
    case .destructive:
      background(Palette.destructive.opacity(0.05), in: RoundedRectangle(cornerRadius: Radius.lg))
        .outlined(radius: Radius.lg, color: Palette.destructive.opacity(0.4))
    case .warning:
      background(Palette.amberSoft, in: RoundedRectangle(cornerRadius: Radius.lg))
    case .muted:
      background(Palette.muted.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.lg))
    }
  }
}
