import SwiftUI
import TypleCore

/// The top of the practice card: the list to switch, the device, the live stats switch and starting again.
struct PracticeHeader: View {
  @Environment(AppModel.self) private var app
  var list: WordList
  var model: PracticeModel
  var onOpenPicker: () -> Void
  var onRestart: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button(action: onOpenPicker) {
        HStack(spacing: 8) {
          Image(systemName: "list.bullet").font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
          Text(list.name).font(.system(size: 16, weight: .bold)).foregroundStyle(Palette.foreground).lineLimit(1)
          Text(L("practice.header.wordCount", list.words.count)).font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
          Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(L("practice.header.switchList", list.name))
      Spacer(minLength: 8)
      DeviceMenu(current: model.running ? model.practiceDevice : app.chosenPracticeDevice, locked: model.running)
      Button {
        app.setLiveStatsVisible(!app.liveStatsVisible)
        if !model.finished { model.focusRequest += 1 }
      } label: {
        Image(systemName: app.liveStatsVisible ? "eye" : "eye.slash").font(.system(size: 16))
      }
      .buttonStyle(.typle(.ghost, size: .iconLg))
      .accessibilityLabel(L("practice.header.liveStats"))
      .accessibilityValue(app.liveStatsVisible ? L("common.on") : L("common.off"))
      Button(action: onRestart) {
        HStack(spacing: 8) {
          Label(L("practice.header.restartShort"), systemImage: "arrow.counterclockwise")
          Kbd(text: "Esc")
        }
      }
      .buttonStyle(.typle(.ghost, size: .lg))
      .accessibilityLabel(L("practice.header.restart"))
    }
    .padding(.horizontal, 12)
    .frame(height: 64)
  }
}

/// Typing or Handwriting, and how to write, for a list marked for Handwriting. Nothing for other lists.
struct PracticeModeBar: View {
  var list: WordList
  var choice: WritingChoice
  /// Asks to change the mode, which waits for a confirmation while a run goes on.
  var onRequestWriting: (Bool) -> Void

  var body: some View {
    if let mark = list.writing {
      let canvas = WritingRecognizer.supports(mark.language)
      VStack(spacing: 8) {
        HStack(spacing: 12) {
          SegmentedPills(options: [(false, L("practice.mode.typing")), (true, L("practice.mode.writing"))],
                         selection: Binding(get: { choice.writing }, set: { onRequestWriting($0) }))
            .accessibilityLabel(L("practice.mode.label"))
          if choice.writing {
            SegmentedPills(options: canvas ? [(WritingMethod.canvas, L("practice.writing.canvas")), (.system, L("practice.writing.system"))]
                                           : [(WritingMethod.system, L("practice.writing.system"))],
                           selection: Binding(get: { canvas ? choice.method : .system }, set: { choice.method = $0 }))
              .accessibilityLabel(L("practice.writing.methodLabel"))
          }
          Spacer(minLength: 0)
        }
        if choice.writing && !canvas {
          Label(L("practice.writing.unsupported"), systemImage: "info.circle")
            .font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 12)
    }
  }
}

/// How far the run is: a bar and 「3 / 20」.
struct PracticeProgressBar: View {
  /// The word being entered (0-based).
  var index: Int
  var total: Int
  var finished: Bool

  var body: some View {
    let done = finished ? total : index
    let current = finished ? total : index + 1
    HStack(spacing: 12) {
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(Palette.muted)
          Capsule().fill(Palette.primary).frame(width: proxy.size.width * CGFloat(done) / CGFloat(max(total, 1)))
        }
      }
      .frame(height: 6)
      Text(L("practice.progress.value", current, total)).font(.system(size: 14, weight: .medium)).monospacedDigit()
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L("practice.progress.label"))
    .accessibilityValue(L("practice.progress.value", current, total))
  }
}
