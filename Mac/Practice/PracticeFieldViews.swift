import AppKit

/// The field, centred in the box SwiftUI draws the border around. A click anywhere in the box focuses it, and while it
/// is not focused, a printable key or Return in the window brings it back without being typed, as in the web app.
final class PracticeInputView: NSView {
  let field = PracticeNSTextField()
  private var monitor: Any?

  override init(frame: NSRect) {
    super.init(frame: frame)
    field.translatesAutoresizingMaskIntoConstraints = false
    addSubview(field)
    NSLayoutConstraint.activate([
      field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      field.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  func focus() {
    window?.makeFirstResponder(field)
  }

  private var focused: Bool {
    window?.firstResponder === field.editor && field.currentEditor() === field.editor
  }

  override func mouseDown(with event: NSEvent) { focus() }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if let monitor { NSEvent.removeMonitor(monitor) }
    monitor = nil
    guard window != nil else { return }
    monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self, self.resumes(on: event) else { return event }
      self.focus()
      return nil
    }
  }

  /// Whether a key brings the field back: the web app's printable key or Enter, with no ⌘, ⌃ or ⌥, in this window
  /// (not a sheet over it), while no other text is being edited.
  private func resumes(on event: NSEvent) -> Bool {
    guard let window, event.window === window, !focused, !(window.firstResponder is NSText) else { return false }
    guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return false }
    if event.keyCode == 36 || event.keyCode == 76 { return true }
    guard let characters = event.characters, characters.unicodeScalars.count == 1, let scalar = characters.unicodeScalars.first else { return false }
    // Function keys (arrows, F1…) arrive as characters in the private use area.
    return !CharacterSet.controlCharacters.contains(scalar) && !(0xF700...0xF8FF).contains(scalar.value)
  }
}

/// A borderless, centred text field whose editor cannot be pasted or dropped into, so that every character is typed.
final class PracticeNSTextField: NSTextField {
  var onFocus: (() -> Void)?

  override class var cellClass: AnyClass? {
    get { PracticeFieldCell.self }
    set {}
  }

  /// The field's own editor, instead of the window's shared one (PracticeFieldCell).
  let editor: PracticeFieldEditor = {
    let editor = PracticeFieldEditor(frame: .zero)
    editor.configure()
    return editor
  }()

  override init(frame: NSRect) {
    super.init(frame: frame)
    isBordered = false
    isBezeled = false
    drawsBackground = false
    // The border and focus ring are drawn around it in SwiftUI, like the web app's input.
    focusRingType = .none
    font = .systemFont(ofSize: 22)
    textColor = .labelColor
    alignment = .center
    usesSingleLineMode = true
    lineBreakMode = .byClipping
    cell?.isScrollable = true
    cell?.wraps = false
    isAutomaticTextCompletionEnabled = false
    allowsCharacterPickerTouchBarItem = false
    setAccessibilityIdentifier("practiceInput")
    setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  override func becomeFirstResponder() -> Bool {
    let became = super.becomeFirstResponder()
    if became { onFocus?() }
    return became
  }

  /// Sets the text, also while it is being edited, and keeps the insertion point at its end.
  func setText(_ text: String) {
    if let editing = currentEditor() as? NSTextView {
      guard editing.string != text else { return }
      editing.string = text
      editing.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
    } else if stringValue != text {
      stringValue = text
    }
  }
}

/// Hands the window the field's own editor when the field starts editing. (The editor is kept by the field: a cell can
/// be copied, and a copy would share it.)
final class PracticeFieldCell: NSTextFieldCell {
  override func fieldEditor(for controlView: NSView) -> NSTextView? {
    (controlView as? PracticeNSTextField)?.editor ?? super.fieldEditor(for: controlView)
  }
}

/// The practice field's editor: no corrections, substitutions, completion or undo, no paste or drop, and a report of
/// every change once the text and its marked (composing) part have settled.
final class PracticeFieldEditor: NSTextView {
  var onChange: (() -> Void)?
  /// Inside an input method's call, whose own changes are reported when it returns.
  private var depth = 0

  func configure() {
    isFieldEditor = true
    isRichText = false
    importsGraphics = false
    allowsUndo = false
    isContinuousSpellCheckingEnabled = false
    isGrammarCheckingEnabled = false
    isAutomaticSpellingCorrectionEnabled = false
    isAutomaticQuoteSubstitutionEnabled = false
    isAutomaticDashSubstitutionEnabled = false
    isAutomaticTextReplacementEnabled = false
    isAutomaticTextCompletionEnabled = false
    isAutomaticDataDetectionEnabled = false
    isAutomaticLinkDetectionEnabled = false
    smartInsertDeleteEnabled = false
    inlinePredictionType = .no
  }

  private func reporting(_ change: () -> Void) {
    depth += 1
    change()
    depth -= 1
    if depth == 0 { onChange?() }
  }

  override func insertText(_ string: Any, replacementRange: NSRange) {
    reporting { super.insertText(string, replacementRange: replacementRange) }
  }

  override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
    reporting { super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange) }
  }

  override func unmarkText() {
    reporting { super.unmarkText() }
  }

  /// Deleting, and any other change made outside the input method's calls.
  override func didChangeText() {
    super.didChangeText()
    if depth == 0 { onChange?() }
  }

  // Pasted, dropped or served text would count as typed.
  override func paste(_ sender: Any?) {}
  override func pasteAsPlainText(_ sender: Any?) {}
  override func pasteAsRichText(_ sender: Any?) {}
  override var acceptableDragTypes: [NSPasteboard.PasteboardType] { [] }
  override func updateDragTypeRegistration() { unregisterDraggedTypes() }
  override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool { false }

  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    switch item.action {
    case #selector(paste(_:)), #selector(pasteAsPlainText(_:)), #selector(pasteAsRichText(_:)): return false
    default: return super.validateUserInterfaceItem(item)
    }
  }
}
