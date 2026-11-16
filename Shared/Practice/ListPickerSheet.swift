import SwiftUI
import TypleCore

/// A list to pick, with a round check like the web's WordListOptions.
struct ListOptionRow: View {
  var list: WordList
  var selected: Bool
  /// The mode the list would be practised in; its best is that mode's.
  var mode = PracticeMode.normal

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: selected ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 18))
        .foregroundStyle(selected ? Palette.primary : Palette.border)
      VStack(alignment: .leading, spacing: 1) {
        Text(list.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.foreground).lineLimit(2)
        Group {
          if let best = listBest(list, mode: mode) {
            Text(L("practice.options.withBest", list.words.count, Format.seconds(best.time)))
          } else {
            Text(L("practice.options.noRecord", list.words.count))
          }
        }
        .font(.system(size: 12))
        .foregroundStyle(Palette.mutedForeground)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(selected ? Palette.muted : .clear, in: RoundedRectangle(cornerRadius: Radius.lg))
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

/// Choosing a list, with a filter by name (the web's 「単語リストを選ぶ」 dialog).
struct ListPickerSheet: View {
  @Environment(\.dismiss) private var dismiss
  var lists: [WordList]
  var selectedId: String?
  /// Whether Handwriting is chosen, so that marked lists show their Handwriting best.
  var writing = false
  var onSelect: (String) -> Void
  @State private var query = ""

  var body: some View {
    let filtered = lists.filter { matchesName($0, query) }
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text(L("practice.picker.title")).font(.system(size: 18, weight: .semibold))
          Text(L("practice.picker.description")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
        }
        Spacer()
        Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 14)) }
          .buttonStyle(.typle(.ghost, size: .icon))
          .accessibilityLabel(L("common.close"))
      }
      SearchField(prompt: L("practice.picker.filter"), text: $query)
      ScrollView {
        VStack(spacing: 2) {
          ForEach(filtered) { list in
            Button {
              dismiss()
              onSelect(list.id)
            } label: { ListOptionRow(list: list, selected: list.id == selectedId, mode: practiceMode(list, writing: writing)) }
              .buttonStyle(.plain)
          }
          if filtered.isEmpty {
            Text(L("practice.picker.noMatch")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
              .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
          }
        }
      }
    }
    .padding(24)
    .frame(maxWidth: 448)
    .background(Palette.card)
    .sheetSize(width: 448, height: 560)
    .presentationDetents([.medium, .large])
  }
}
