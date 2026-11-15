import SwiftUI
import TypleCore

/// A word as the list editor holds it, with an id of its own while it is edited.
struct ListEditorRow: Identifiable, Equatable {
  let id = UUID()
  var word: Word
  var filled: Bool { !word.display.isEmpty || !word.input.isEmpty || !word.annotation.isEmpty }

  /// A new empty row, with its own id each time.
  static var empty: ListEditorRow { ListEditorRow(word: Word(display: "", input: "")) }

  /// A saved word as the editor shows it: an input equal to the word shown is empty, as the web editor does.
  init(editing word: Word) {
    self.init(word: Word(display: word.display, input: word.input == word.display ? "" : word.input, annotation: word.annotation))
  }

  init(word: Word) { self.word = word }

  /// The word to save: an empty input means the same as the word shown.
  var saved: Word {
    Word(display: word.display, input: word.input.isEmpty ? word.display : word.input, annotation: word.annotation, inputType: word.inputType)
  }
}

/// The list editor's fields, for moving the focus on with Return.
enum ListEditorField: Hashable {
  case name, display(UUID), input(UUID), annotation(UUID)
}

/// One word of the list editor: the drag handle and number, the word shown, what to type and the note, and its menu.
struct WordRowView: View {
  @Binding var row: ListEditorRow
  var index: Int
  /// How many rows the list has, for the menu's moves and for keeping the last empty row.
  var count: Int
  var error: String?
  var focus: FocusState<ListEditorField?>.Binding
  /// Return in a field: the editor moves the focus on.
  var onSubmit: (ListEditorField) -> Void
  var onMove: (_ from: Int, _ to: Int) -> Void
  var onRemove: (Int) -> Void
  /// A row dropped here by its id; false when it is not one of the list's rows.
  var onDrop: (UUID) -> Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 12) {
        HStack(spacing: 14) {
          Image(systemName: "line.3.horizontal").font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
            .frame(width: 20, height: 36)
            .contentShape(Rectangle())
            .draggable(row.id.uuidString)
            .accessibilityLabel(L("wordLists.wordRow.drag", index + 1))
          Text("\(index + 1)").font(.system(size: 14)).monospacedDigit().foregroundStyle(Palette.mutedForeground)
        }
        .frame(width: 60, alignment: .leading)
        cell(L("wordLists.editor.displayPlaceholder"), $row.word.display, field: .display(row.id), invalid: error != nil && row.word.display.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
             label: L("wordLists.editor.displayLabel", index + 1))
        cell(row.word.display, $row.word.input, field: .input(row.id), invalid: error != nil && !row.word.input.isEmpty,
             label: L("wordLists.editor.inputLabel", index + 1))
        cell(L("wordLists.editor.annotationPlaceholder"), $row.word.annotation, field: .annotation(row.id), invalid: false,
             label: L("wordLists.editor.annotationLabel", index + 1))
        Menu {
          Button { onMove(index, index - 1) } label: { Label(L("wordLists.editor.moveUp"), systemImage: "arrow.up") }.disabled(index == 0)
          Button { onMove(index, index + 1) } label: { Label(L("wordLists.editor.moveDown"), systemImage: "arrow.down") }.disabled(index == count - 1)
          Button { onMove(index, 0) } label: { Label(L("wordLists.editor.moveFirst"), systemImage: "arrow.up.to.line") }.disabled(index == 0)
          Button { onMove(index, count - 1) } label: { Label(L("wordLists.editor.moveLast"), systemImage: "arrow.down.to.line") }.disabled(index == count - 1)
          Divider()
          Button(role: .destructive) { onRemove(index) } label: { Label(L("wordLists.editor.deleteWord"), systemImage: "trash") }
        } label: {
          Image(systemName: "ellipsis").font(.system(size: 14)).frame(width: 32, height: 36).contentShape(Rectangle())
        }
        .plainMenu()
        .foregroundStyle(Palette.foreground)
        .accessibilityLabel(L("wordLists.editor.wordActions", index + 1))
        Button { onRemove(index) } label: { Image(systemName: "trash").font(.system(size: 14)) }
          .buttonStyle(.typle(.ghost, size: .icon))
          .foregroundStyle(Palette.mutedForeground)
          .disabled(count == 1 && !row.filled)
          .accessibilityLabel(L("wordLists.editor.deleteWordN", index + 1))
      }
      if let error {
        Text(error).font(.system(size: 12)).foregroundStyle(Palette.destructive).padding(.leading, 72)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 8)
    .dropDestination(for: String.self) { items, _ in
      guard let id = items.first.flatMap(UUID.init(uuidString:)) else { return false }
      return onDrop(id)
    }
  }

  private func cell(_ placeholder: String, _ text: Binding<String>, field: ListEditorField, invalid: Bool, label: String) -> some View {
    TextField(placeholder, text: text)
      .font(.system(size: 14))
      .plainInput()
      .focused(focus, equals: field)
      .submitLabel(.next)
      .onSubmit { onSubmit(field) }
      .padding(.horizontal, 12)
      .frame(height: 40)
      .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.md))
      .outlined(radius: Radius.md, color: invalid ? Palette.destructive : Palette.input)
      .frame(maxWidth: .infinity)
      .accessibilityLabel(label)
  }
}
