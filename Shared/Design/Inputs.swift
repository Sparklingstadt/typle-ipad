import SwiftUI

/// A search box with a magnifier, like the web's list and ranking searches.
struct SearchField: View {
  var prompt: String
  @Binding var text: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
      TextField(prompt, text: $text)
        .font(.system(size: 14))
        .plainInput()
      if !text.isEmpty {
        Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.mutedForeground) }
          .buttonStyle(.plain)
          .accessibilityLabel(L("common.clearSearch"))
      }
    }
    .padding(.horizontal, 12)
    .frame(height: 40)
    .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.md))
    .outlined(radius: Radius.md, color: Palette.input)
  }
}

/// A text field with shadcn's Input look.
struct InputBox: View {
  var placeholder: String
  @Binding var text: String
  var invalid = false
  var height: CGFloat = 40

  var body: some View {
    TextField(placeholder, text: $text)
      .font(.system(size: 14))
      .plainInput()
      .padding(.horizontal, 12)
      .frame(minHeight: height)
      .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.md))
      .outlined(radius: Radius.md, color: invalid ? Palette.destructive : Palette.input)
  }
}

/// A rounded-full filter button showing its name and value, like 「リスト すべて ⌄」.
struct FilterLabel: View {
  var name: String
  var value: String

  var body: some View {
    HStack(spacing: 6) {
      Text(name).foregroundStyle(Palette.mutedForeground)
      Text(value).foregroundStyle(Palette.foreground).fontWeight(.medium).lineLimit(1)
      Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold)).foregroundStyle(Palette.mutedForeground)
    }
    .font(.system(size: 14))
    .padding(.horizontal, 14)
    .frame(height: 36)
    .background(Palette.card, in: Capsule())
    .overlay(Capsule().strokeBorder(Palette.border))
  }
}

/// Two or more choices on a muted track, the selected one raised (the web's ToggleGroup).
struct SegmentedPills<Value: Hashable>: View {
  var options: [(Value, String)]
  @Binding var selection: Value

  var body: some View {
    HStack(spacing: 2) {
      ForEach(options.indices, id: \.self) { index in
        let value = options[index].0
        Button { selection = value } label: {
          Text(options[index].1)
            .font(.system(size: 13, weight: selection == value ? .semibold : .regular))
            .foregroundStyle(selection == value ? Palette.foreground : Palette.mutedForeground)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(selection == value ? Palette.card : .clear, in: Capsule())
            .shadow(color: .black.opacity(selection == value ? 0.08 : 0), radius: 1, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == value ? .isSelected : [])
      }
    }
    .padding(3)
    .background(Palette.muted, in: Capsule())
    .outlined(radius: 20)
  }
}
