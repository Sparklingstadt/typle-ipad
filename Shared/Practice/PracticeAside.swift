import SwiftUI
import TypleCore

/// Beside the practice card (below it when narrow): the lists to switch to, and the best runs of this list in the
/// mode now shown.
struct PracticeAside: View {
  @Environment(AppModel.self) private var app
  var list: WordList
  var model: PracticeModel
  var choice: WritingChoice
  /// Asks to switch to a list, which waits for a confirmation while a run goes on.
  var onSelect: (String) -> Void
  var onShowAllLists: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      lists
      best
    }
  }

  private var lists: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(L("practice.aside.lists")).font(.system(size: 15, weight: .bold))
        Spacer()
        Button { app.navigate(.createList) } label: { Label(L("practice.aside.create"), systemImage: "plus") }
          .buttonStyle(.typle(.ghost, size: .lg))
      }
      .padding(.leading, 8)
      ForEach(app.lists.prefix(8)) { item in
        Button { onSelect(item.id) } label: { ListOptionRow(list: item, selected: item.id == list.id, mode: choice.mode(for: item)) }
          .buttonStyle(.plain)
      }
      if app.lists.count > 8 {
        Button(L("practice.aside.allLists"), action: onShowAllLists).buttonStyle(.typle(.ghost))
      }
    }
    .padding(12)
    .card()
  }

  private var best: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(L("practice.aside.best")).font(.system(size: 15, weight: .bold))
        Text(list.name).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground).lineLimit(1)
      }
      let mode = model.mode
      let candidates = comparableRecords(list, mode: mode)
      Text(candidates.count < recordsOfMode(list.records, mode).count ? L("practice.aside.bestOrderAtCount", list.words.count) : L("practice.aside.bestOrder"))
        .font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
      BestRecordsView(records: candidates, highlightId: model.saveState == .saved ? model.record?.id : nil)
      Button { app.showRankings(listId: list.id, mode: model.mode) } label: {
        HStack(spacing: 4) { Text(L("practice.aside.allBest")); Image(systemName: "arrow.right").font(.system(size: 11)) }
          .font(.system(size: 13, weight: .medium))
      }
      .buttonStyle(.typle(.ghost, size: .sm))
    }
    .padding(16)
    .card()
  }
}
