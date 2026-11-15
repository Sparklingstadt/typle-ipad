import AppKit
import SwiftUI

/// The practice input on the Mac, in place of the iPad's UITextField (iPad/Practice/PracticeTextField.swift).
/// Text being composed by an input method (romaji, pinyin) is shown but never judged: only text committed with no
/// marked text reaches `onCommit`, like compositionstart/compositionend in the web app.
struct PracticeTextField: NSViewRepresentable {
  /// The judged input; the field is set to it whenever nothing is being composed.
  var text: String
  var placeholder: String
  /// Changing this number focuses the field.
  var focusRequest: Int
  var onCommit: (String) -> Void
  var onComposingChange: (Bool) -> Void
  var onFocusChange: (Bool) -> Void
  var onEscape: () -> Void
  /// Return, when nothing is being composed (Handwriting checks the word on it); typing leaves it out.
  var onReturn: (() -> Void)? = nil
  /// The language of the list in Handwriting. The Mac has no hint for an input source, so it is not used.
  var language: String? = nil

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  func makeNSView(context: Context) -> PracticeInputView {
    let view = PracticeInputView()
    let coordinator = context.coordinator
    view.field.delegate = coordinator
    view.field.onFocus = { [weak coordinator] in coordinator?.parent.onFocusChange(true) }
    view.field.editor.onChange = { [weak coordinator, weak view] in
      guard let view else { return }
      coordinator?.changed(view.field.editor)
    }
    return view
  }

  func updateNSView(_ view: PracticeInputView, context: Context) {
    context.coordinator.parent = self
    view.field.placeholderString = placeholder
    view.field.setAccessibilityLabel(placeholder)
    // Replacing the text while something is being composed would cancel the composition.
    if !view.field.editor.hasMarkedText() { view.field.setText(text) }
    if context.coordinator.focusRequest != focusRequest {
      context.coordinator.focusRequest = focusRequest
      DispatchQueue.main.async { view.focus() }
    }
  }

  final class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: PracticeTextField
    var focusRequest: Int
    private var composing = false

    init(_ parent: PracticeTextField) {
      self.parent = parent
      focusRequest = parent.focusRequest - 1
    }

    func changed(_ editor: NSTextView) {
      let isComposing = editor.hasMarkedText()
      if isComposing != composing {
        composing = isComposing
        parent.onComposingChange(isComposing)
      }
      if !isComposing { parent.onCommit(editor.string) }
    }

    func controlTextDidEndEditing(_ notification: Notification) { parent.onFocusChange(false) }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
      switch selector {
      case #selector(NSResponder.cancelOperation(_:)):
        // Esc restarts, unless it is cancelling a composition (the input method takes it first).
        if !textView.hasMarkedText() { parent.onEscape() }
        return true
      case #selector(NSResponder.insertNewline(_:)), #selector(NSResponder.insertLineBreak(_:)),
           #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)), #selector(NSTextView.complete(_:)):
        // Return does nothing in typing, where words advance when they are typed correctly; Handwriting checks the
        // word. Esc's completion list is not wanted.
        if selector != #selector(NSTextView.complete(_:)) && !textView.hasMarkedText() { parent.onReturn?() }
        return true
      default:
        return false
      }
    }
  }
}
