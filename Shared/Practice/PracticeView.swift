import SwiftUI
import TypleCore

/// The practice screen (src/app/(workspace)/play/page.tsx): the practice card, and beside it (below when narrow) the
/// lists and the best records.
struct PracticeView: View {
  @Environment(AppModel.self) private var app
  @State private var model = PracticeModel()
  @State private var choice = WritingChoice()
  /// A change of practice mode asked for mid-run, waiting for the same confirmation as a change of list.
  @State private var pendingWriting: Bool?
  @Environment(\.scenePhase) private var scenePhase
  @State private var pickerOpen = false
  @State private var pendingSwitch: String?
  @State private var showAll = false
  @State private var inputFocused = false
  @State private var focusedOnce = false

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        Group {
          if let list = model.list(in: app.lists), !list.words.isEmpty {
            if proxy.size.width >= 900 {
              HStack(alignment: .top, spacing: 24) {
                card(list)
                aside(list).frame(width: 320)
              }
            } else {
              VStack(spacing: 24) {
                card(list)
                aside(list)
              }
            }
          } else {
            empty
          }
        }
        .frame(maxWidth: 1280)
        .padding(.horizontal, proxy.size.width >= 900 ? 48 : 20)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.never)
      .background(Palette.page)
    }
    .sheet(isPresented: $pickerOpen, onDismiss: { if !model.finished { model.focusRequest += 1 } }) {
      ListPickerSheet(lists: app.lists, selectedId: model.list(in: app.lists)?.id, writing: choice.writing, onSelect: requestSwitch)
    }
    .alert(L("practice.switch.title"), isPresented: Binding(get: { pendingSwitch != nil }, set: { if !$0 { pendingSwitch = nil } })) {
      Button(L("practice.switch.continue"), role: .cancel) { model.focusRequest += 1 }
      Button(L("practice.switch.confirm"), role: .destructive) { if let id = pendingSwitch { switchTo(id) } }
    } message: {
      if let current = model.list(in: app.lists) {
        Text(L("practice.switch.description", current.name, model.session.index, current.words.count,
               app.lists.first { $0.id == pendingSwitch }?.name ?? ""))
      }
    }
    .alert(L("practice.switch.title"), isPresented: Binding(get: { pendingWriting != nil }, set: { if !$0 { pendingWriting = nil } })) {
      Button(L("practice.switch.continue"), role: .cancel) { model.focusRequest += 1 }
      Button(L("practice.modeSwitch.confirm"), role: .destructive) {
        if let writing = pendingWriting { choose(writing: writing) }
      }
    } message: {
      if let current = model.list(in: app.lists) {
        Text(L("practice.modeSwitch.description", current.name, model.session.index, current.words.count))
      }
    }
    .onAppear {
      takeRequest()
      // The mode chosen on an earlier visit, for the list now shown.
      syncMode()
    }
    // The clock of a Handwriting run stops while the app is not in front (typing has no pause yet).
    .onChange(of: scenePhase) { if scenePhase != .active && model.mode == .writing { model.pause() } }
    // A list that gains or loses its mark, or a run on a list that changed, starts in the mode it now has.
    .onChange(of: choice.mode(for: model.list(in: app.lists))) { syncMode() }
    .onChange(of: model.list(in: app.lists)?.writing) { syncMode() }
    #if DEBUG
    .task {
      // Handwriting screenshots: `-TypleWriting "爱护|xx"` checks each text as if written into the field, Return after each.
      guard let text = UserDefaults.standard.string(forKey: "TypleWriting"), let list = model.list(in: app.lists) else { return }
      try? await Task.sleep(for: .milliseconds(300))
      choice.writing = true
      choice.method = .system
      syncMode()
      for written in text.split(separator: "|").map(String.init) {
        model.judge([written], list: list, explicit: true, device: app.chosenPracticeDevice, app: app)
        try? await Task.sleep(for: .milliseconds(200))
      }
    }
    .task {
      // Screenshots of a run in progress or finished: `-TypleTyping hogefx` types as if from the keyboard.
      guard let text = UserDefaults.standard.string(forKey: "TypleTyping"), let list = model.list(in: app.lists) else { return }
      try? await Task.sleep(for: .milliseconds(300))
      var typed = ""
      for character in text {
        typed.append(character)
        let index = model.session.index
        model.enter(typed, list: list, device: app.chosenPracticeDevice, app: app)
        // A finished word clears the field, so the next characters start a new input.
        if model.session.index != index || model.finished { typed = "" }
        try? await Task.sleep(for: .milliseconds(60))
      }
    }
    #endif
    .onChange(of: app.practiceRequest) { takeRequest() }
    // Another store has other lists; a run on a list that is gone cannot be saved.
    .onChange(of: app.store.accountId) {
      let list = app.lists.first
      model.restart(listId: list?.id, mode: choice.mode(for: list), language: list?.writing?.language)
    }
  }

  private var empty: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L("practice.empty")).font(.system(size: 16))
      Button { app.navigate(.createList) } label: { Label(L("nav.links.create"), systemImage: "plus") }.buttonStyle(.typle())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(32)
    .card()
  }

  private func takeRequest() {
    guard let id = app.practiceRequest else {
      model.focusRequest += 1
      return
    }
    app.practiceRequest = nil
    if model.running && id != model.listId { pendingSwitch = id } else { switchTo(id) }
  }

  private func requestSwitch(_ id: String) {
    if !model.running { switchTo(id) }
    else if id != model.list(in: app.lists)?.id { pendingSwitch = id }
  }

  private func switchTo(_ id: String) {
    pendingSwitch = nil
    showAll = false
    let list = app.lists.first { $0.id == id }
    model.restart(listId: id, mode: choice.mode(for: list), language: list?.writing?.language)
  }

  /// Starts again on the same list, in the mode it has now: a mark taken off or put on during the last run counts from
  /// the next one.
  private func restartRun() {
    let list = model.list(in: app.lists)
    model.restart(mode: choice.mode(for: list), language: list?.writing?.language)
  }

  /// Starts a run in the mode the list and the choice give, unless one is under way (it keeps its mode to the end).
  private func syncMode() {
    guard !model.running, !model.finished else { return }
    let list = model.list(in: app.lists)
    let mode = choice.mode(for: list)
    if mode != model.mode || (mode == .writing && list?.writing?.language != model.language) {
      model.restart(mode: mode, language: list?.writing?.language)
    }
  }

  private func requestWriting(_ writing: Bool) {
    guard writing != choice.writing else { return }
    if model.running { pendingWriting = writing } else { choose(writing: writing) }
  }

  private func choose(writing: Bool) {
    pendingWriting = nil
    choice.writing = writing
    let list = model.list(in: app.lists)
    model.restart(mode: choice.mode(for: list), language: list?.writing?.language)
  }


  // MARK: The practice card

  private func card(_ list: WordList) -> some View {
    VStack(spacing: 0) {
      PracticeHeader(list: list, model: model, onOpenPicker: { pickerOpen = true }, onRestart: restartRun)
      Hairline()
      PracticeModeBar(list: list, choice: choice, onRequestWriting: requestWriting)
      PracticeProgressBar(index: model.session.index, total: list.words.count, finished: model.finished)
      if model.finished {
        PracticeResultView(list: list, session: model.session, device: model.practiceDevice, mode: model.mode, record: model.record, saveState: model.saveState,
                           onRestart: { restartRun() }, onRetry: { model.retrySave(app: app) }, onChooseList: { pickerOpen = true })
      } else if model.mode == .writing {
        writing(list)
      } else {
        typing(list)
      }
    }
    .frame(maxWidth: .infinity)
    .card()
  }

  @ViewBuilder
  private func typing(_ list: WordList) -> some View {
    TypingPracticeView(list: list, model: model, inputFocused: $inputFocused, focusedOnce: $focusedOnce,
                       paused: pickerOpen || pendingSwitch != nil, onRestart: restartRun)
    if app.liveStatsVisible {
      LiveStatsView(session: model.session).padding(.horizontal, 24).padding(.bottom, 20)
    }
    Hairline()
    upcoming(list)
  }

  @ViewBuilder
  private func writing(_ list: WordList) -> some View {
    let canvas = list.writing.map { WritingRecognizer.supports($0.language) } ?? false
    WritingPracticeView(list: list, model: model, method: canvas ? choice.method : .system, inputFocused: $inputFocused, onRestart: restartRun)
    if app.liveStatsVisible {
      LiveStatsView(session: model.session, showsSpeed: false).padding(.horizontal, 24).padding(.bottom, 20)
    }
    Hairline()
    upcoming(list)
  }

  private func upcoming(_ list: WordList) -> some View {
    UpcomingWordsView(words: list.words, index: model.session.index, showAll: $showAll) { model.focusRequest += 1 }
  }

  // MARK: Beside the card

  private func aside(_ list: WordList) -> some View {
    PracticeAside(list: list, model: model, choice: choice, onSelect: requestSwitch, onShowAllLists: { pickerOpen = true })
  }
}
