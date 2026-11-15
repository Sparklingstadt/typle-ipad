import SwiftUI
import TypleCore

/// The next few words under the practice card, and all of them when opened, marked done, current or still to come.
struct UpcomingWordsView: View {
  var words: [Word]
  var index: Int
  @Binding var showAll: Bool
  /// After the list opens or closes, to give the focus back to the field.
  var onToggle: () -> Void

  var body: some View {
    let next = Array(words.dropFirst(index + 1).prefix(3))
    let remaining = words.count - index - 1 - next.count
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text(L("practice.upcoming.next")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
        ForEach(next.indices, id: \.self) { chip(next[$0].display) }
        if next.isEmpty { Text(L("practice.upcoming.last")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground) }
        if remaining > 0 { Text(L("practice.upcoming.more", remaining)).font(.system(size: 12)).foregroundStyle(Palette.pending) }
        Spacer(minLength: 0)
        Button {
          showAll.toggle()
          onToggle()
        } label: {
          HStack(spacing: 6) {
            Text(L("practice.upcoming.showAll"))
            Image(systemName: showAll ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .semibold))
          }
        }
        .buttonStyle(.typle(.ghost, size: .lg))
      }
      if showAll {
        ScrollViewReader { proxy in
          ScrollView {
            FlowLayout(spacing: 6, lineSpacing: 6, alignment: .leading) {
              ForEach(words.indices, id: \.self) { offset in
                chip(words[offset].display, state: offset < index ? .done : offset == index ? .current : .pending).id(offset)
              }
            }
            .padding(.vertical, 10)
          }
          .frame(maxHeight: 176)
          .overlay(alignment: .top) {
            Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3])).foregroundStyle(Palette.border).frame(height: 1)
          }
          .onAppear { proxy.scrollTo(index, anchor: .center) }
          .onChange(of: index) { proxy.scrollTo(index, anchor: .center) }
        }
      }
    }
    .padding(.leading, 24)
    .padding(.trailing, 12)
    .padding(.vertical, 10)
    .frame(minHeight: 56)
  }

  private enum ChipState { case done, current, pending }

  private func chip(_ text: String, state: ChipState = .pending) -> some View {
    Text(text)
      .font(.system(size: 13))
      .lineLimit(1)
      .padding(.horizontal, 12)
      .frame(height: 28)
      .foregroundStyle(state == .current ? Palette.primaryForeground : state == .done ? Palette.success : Palette.mutedForeground)
      .background(state == .current ? Palette.primary : state == .done ? Palette.successSoft : .clear, in: Capsule())
      .overlay(Capsule().strokeBorder(state == .pending ? Palette.border : .clear))
      .accessibilityLabel(text + (state == .done ? L("practice.upcoming.done") : state == .current ? L("practice.upcoming.current") : ""))
  }
}
