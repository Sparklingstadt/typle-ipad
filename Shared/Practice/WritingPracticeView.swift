import SwiftUI
import TypleCore

/// One word of a Handwriting run (Typle Handwriting): the word to copy, and the canvas or the field it is written in.
/// A word moves on as soon as what is written matches; a check (判定, Return) that does not match is a mistake, and so
/// is skipping. On the canvas, a pause of 0.8 s in writing reads it silently, which only ever moves on.
struct WritingPracticeView: View {
  @Environment(AppModel.self) private var app
  var list: WordList
  var model: PracticeModel
  var method: WritingMethod
  /// Whether the field had focus, for the resume button over the word, as in typing.
  @Binding var inputFocused: Bool
  /// Esc in the field: starts again in the mode the list has now.
  var onRestart: () -> Void

  @State private var strokes: [WritingStroke] = []
  /// Counts changes to the strokes, so that a reading of older strokes is dropped.
  @State private var generation = 0
  @State private var reading: Task<Void, Never>?
  /// When the last stroke ended: a silent match counts from then, not from when Vision finished.
  @State private var strokeEnded: Double?
  /// The strokes an explicit check is reading, so that pressing 判定 again (or holding Return) counts them once.
  @State private var checking: RecognitionToken?
  @State private var canvasSize = CGSize(width: 600, height: 200)
  @State private var text = ""

  private static let idleDelay = Duration.milliseconds(800)

  var body: some View {
    let words = list.words
    let word = words[min(model.session.index, words.count - 1)]
    VStack(spacing: 14) {
      if !word.annotation.isEmpty {
        Text(word.annotation).font(.system(size: 16)).multilineTextAlignment(.center)
      }
      Text(word.display).font(.system(size: wordSize(word.display), weight: .medium)).multilineTextAlignment(.center)
        .accessibilityLabel(L("practice.writing.copyThis", word.display))
    }
    .frame(maxWidth: .infinity, minHeight: 160)
    .padding(.horizontal, 24)
    .padding(.top, 32)
    VStack(spacing: 12) {
      switch method {
      case .canvas: canvas
      case .system: field
      }
      buttons
      feedback
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, 20)
    .onChange(of: model.session.index) { clear() }
    .onChange(of: model.session.startedAt == nil) { if model.session.startedAt == nil { clear() } }
    .onChange(of: method) { clear() }
    .onDisappear { reading?.cancel() }
  }

  // MARK: The canvas

  private var canvas: some View {
    WritingCanvas(strokes: $strokes, onStrokeStart: {
      generation += 1
      reading?.cancel()
      model.beginWriting(device: app.chosenPracticeDevice)
    }, onStrokeEnd: {
      generation += 1
      strokeEnded = model.now
      readLater()
    })
    .frame(height: 200)
    .frame(maxWidth: 720)
    .background(GeometryReader { proxy in Color.clear.onAppear { canvasSize = proxy.size }.onChange(of: proxy.size) { canvasSize = proxy.size } })
    .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.lg))
    .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(model.writingFeedback != nil ? Palette.destructive : Palette.input, lineWidth: 2))
  }

  /// Reads the writing once it has rested for a moment; writing on cancels it.
  private func readLater() {
    reading?.cancel()
    reading = Task {
      try? await Task.sleep(for: Self.idleDelay)
      guard !Task.isCancelled else { return }
      await read(explicit: false)
    }
  }

  private var token: RecognitionToken { RecognitionToken(run: model.run, index: model.session.index, generation: generation) }

  private func read(explicit: Bool) async {
    let started = token
    guard !strokes.isEmpty, let image = WritingCanvas.image(of: strokes, size: canvasSize) else {
      if explicit { model.judge([], list: list, explicit: true, device: app.chosenPracticeDevice, app: app) }
      return
    }
    if explicit {
      guard checking != started else { return }
      checking = started
    }
    let candidates = await WritingRecognizer.recognize(image, language: model.language)
    guard started == token else { return }
    // A silent match is timed at the end of the writing; a check, when it was asked for.
    model.judge(candidates, list: list, explicit: explicit, device: app.chosenPracticeDevice, app: app,
                at: explicit ? nil : strokeEnded)
  }

  private func clear() {
    reading?.cancel()
    strokes = []
    text = ""
    generation += 1
  }

  // MARK: The system's handwriting input

  private var field: some View {
    PracticeTextField(
      text: text, placeholder: L("practice.writing.input"),
      focusRequest: model.focusRequest,
      onCommit: { value in
        text = value
        if !value.isEmpty { model.beginWriting(device: app.chosenPracticeDevice) }
        model.judge([value], list: list, explicit: false, device: app.chosenPracticeDevice, app: app)
      },
      onComposingChange: { model.setComposing($0) },
      onFocusChange: { focused in
        inputFocused = focused
        if !focused { model.pause() }
      },
      onEscape: { onRestart() },
      onReturn: { model.judge([text], list: list, explicit: true, device: app.chosenPracticeDevice, app: app) },
      language: model.language.rawValue)
      .frame(height: 56)
      .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.lg))
      .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(
        model.writingFeedback != nil ? Palette.destructive : inputFocused ? Palette.primary : Palette.input, lineWidth: 2))
      .frame(maxWidth: 440)
  }

  // MARK: Buttons and feedback

  private var buttons: some View {
    HStack(spacing: 8) {
      if method == .canvas {
        Button {
          guard !strokes.isEmpty else { return }
          strokes.removeLast()
          generation += 1
          if !strokes.isEmpty { readLater() }
        } label: { Label(L("practice.writing.undo"), systemImage: "arrow.uturn.backward") }
          .buttonStyle(.typle(.outline))
          .disabled(strokes.isEmpty)
        Button { clear() } label: { Label(L("practice.writing.clear"), systemImage: "eraser") }
          .buttonStyle(.typle(.outline))
          .disabled(strokes.isEmpty)
      }
      Button {
        switch method {
        case .canvas:
          reading?.cancel()
          Task { await read(explicit: true) }
        case .system:
          // What is still being composed is not written yet, as Return in the field waits for it.
          guard !model.composing else { return }
          model.judge([text], list: list, explicit: true, device: app.chosenPracticeDevice, app: app)
        }
      } label: {
        HStack(spacing: 8) { Text(L("practice.writing.check")); Kbd(text: "Return") }
      }
      .buttonStyle(.typle())
      // The field takes Return itself; on the canvas it is this button's shortcut.
      .keyboardShortcut(method == .canvas ? KeyboardShortcut(.return, modifiers: []) : nil)
      Button {
        reading?.cancel()
        model.skip(list: list, device: app.chosenPracticeDevice, app: app)
      } label: { Label(L("practice.writing.skip"), systemImage: "forward") }
        .buttonStyle(.typle(.ghost))
    }
    .labelStyle(TightLabelStyle())
  }

  private var feedback: some View {
    Group {
      switch model.writingFeedback {
      case .read(let read):
        Label(L("practice.writing.read", read), systemImage: "exclamationmark.circle").foregroundStyle(Palette.destructive)
      case .unreadable:
        Label(L("practice.writing.unreadable"), systemImage: "exclamationmark.circle").foregroundStyle(Palette.destructive)
      case nil:
        Text(L(method == .canvas ? "practice.writing.canvasHint" : "practice.writing.systemHint")).foregroundStyle(Palette.mutedForeground)
      }
    }
    .labelStyle(TightLabelStyle())
    .font(.system(size: 13, weight: .medium))
    .multilineTextAlignment(.center)
    .frame(minHeight: 20)
    .accessibilityAddTraits(.updatesFrequently)
  }

  /// The same sizes as the typing word.
  private func wordSize(_ text: String) -> CGFloat {
    let length = text.unicodeScalars.count
    if length > 24 { return 26 }
    return length > 10 ? 44 : 64
  }
}
