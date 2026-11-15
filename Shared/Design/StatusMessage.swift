import SwiftUI

/// What came of an action on a page, such as deleting or connecting: a success to confirm, or why it failed.
struct StatusMessage: Equatable {
  var text: String
  var failed: Bool

  static func done(_ text: String) -> StatusMessage { StatusMessage(text: text, failed: false) }
  static func failure(_ text: String) -> StatusMessage { StatusMessage(text: text, failed: true) }
  static func failure(_ error: Error) -> StatusMessage { .failure(errorText(error)) }
}

/// A status message under a page's heading: green with a check, or red with a warning.
struct StatusLabel: View {
  var status: StatusMessage
  var size: CGFloat = 14

  var body: some View {
    Label(status.text, systemImage: status.failed ? "exclamationmark.triangle" : "checkmark.circle")
      .font(.system(size: size)).foregroundStyle(status.failed ? Palette.destructive : Palette.success)
  }
}
