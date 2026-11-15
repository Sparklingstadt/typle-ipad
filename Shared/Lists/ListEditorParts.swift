import SwiftUI
import TypleCore

/// Whether the list is for Handwriting, and the language its words are written in.
struct WritingMarkCard: View {
  @Binding var writing: WritingMark?

  /// The names of the recognition languages in their own language, the same in every display language (as the web app
  /// shows them).
  static let languageNames: [WritingLanguage: String] = [
    .en: "English", .ja: "日本語", .zhHans: "中文（简体）", .zhHant: "中文（繁體）", .ko: "한국어",
    .fr: "Français", .de: "Deutsch", .es: "Español", .ru: "Русский", .cs: "Čeština",
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Toggle(isOn: Binding(get: { writing != nil }, set: { on in
        // Turned on, the language starts as the display language's, or English.
        writing = on ? WritingMark(language: Localization.locale.language.languageCode?.identifier == "ja" ? .ja : .en) : nil
      })) {
        Text(L("wordLists.editor.writingToggle")).font(.system(size: 14, weight: .semibold))
      }
      Text(L("wordLists.editor.writingToggleHelp")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
      if let mark = writing {
        HStack(spacing: 12) {
          Menu {
            Picker(L("wordLists.editor.writingLanguage"), selection: Binding(get: { mark.language }, set: { writing = WritingMark(language: $0) })) {
              ForEach(WritingLanguage.allCases, id: \.self) { language in
                Text(Self.languageNames[language] ?? language.rawValue).tag(language)
              }
            }
            .menuPicker()
          } label: {
            FilterLabel(name: L("wordLists.editor.writingLanguage"), value: Self.languageNames[mark.language] ?? mark.language.rawValue)
          }
          .plainMenu()
        }
      }
    }
    .padding(24)
    .card()
  }
}

/// The column headings above the words: #, the word shown, what to type and the note.
struct WordTableHeader: View {
  var body: some View {
    HStack(spacing: 12) {
      Text("#").frame(width: 60, alignment: .leading)
      HStack(spacing: 0) { Text(L("wordLists.editor.display")); Text("*").foregroundStyle(Palette.destructive) }
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 4) {
        Text(L("wordLists.editor.input")).foregroundStyle(Palette.foreground)
        Text(L("wordLists.editor.inputHint"))
      }
      .lineLimit(1)
      .minimumScaleFactor(0.75)
      .frame(maxWidth: .infinity, alignment: .leading)
      Text(L("wordLists.editor.annotationOptional")).frame(maxWidth: .infinity, alignment: .leading)
      // The width of a row's menu and delete buttons.
      Color.clear.frame(width: 76, height: 1)
    }
    .font(.system(size: 12, weight: .medium))
    .foregroundStyle(Palette.mutedForeground)
    .padding(.horizontal, 24)
    .frame(height: 34)
    .background(Palette.muted.opacity(0.5))
    .hairline(.top)
    .hairline(.bottom)
  }
}

/// The keys of the editor, under the words.
struct WordEditorHints: View {
  var body: some View {
    HStack(spacing: 8) {
      Kbd(text: "Enter"); Text(L("wordLists.editor.shortcutNext"))
      Text("・")
      Kbd(text: "⌘+Enter"); Text(L("wordLists.editor.shortcutSave"))
      Text("・")
      Image(systemName: "line.3.horizontal").font(.system(size: 11)); Text(L("wordLists.editor.shortcutDrag"))
    }
    .font(.system(size: 12))
    .foregroundStyle(Palette.mutedForeground)
  }
}

/// Whether there are changes, how many words, and cancelling or saving (⌘+Enter).
struct ListEditorFooter: View {
  var changed: Bool
  var wordCount: Int
  var saving: Bool
  var onCancel: () -> Void
  var onSave: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text(changed ? L("wordLists.editor.unsaved") : L("wordLists.editor.noChanges"))
        .foregroundStyle(changed ? Palette.foreground : Palette.mutedForeground)
      Text(L("wordLists.editor.wordTotal", wordCount)).foregroundStyle(Palette.mutedForeground)
      Spacer()
      Button(L("common.form.cancel"), action: onCancel).buttonStyle(.typle(.ghost, size: .lg))
      Button(action: onSave) {
        HStack(spacing: 8) {
          Text(L("wordLists.editor.save"))
          Text("⌘+Enter").font(.system(size: 11)).foregroundStyle(Palette.primaryForeground.opacity(0.6))
        }
      }
      .buttonStyle(.typle(.primary, size: .lg))
      .keyboardShortcut(.return, modifiers: .command)
      .disabled(saving)
    }
    .font(.system(size: 14))
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .card()
    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
  }
}
