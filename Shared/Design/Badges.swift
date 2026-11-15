import SwiftUI

/// A keyboard key, like the web's <Kbd>.
struct Kbd: View {
  var text: String
  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .medium))
      .foregroundStyle(Palette.mutedForeground)
      .padding(.horizontal, 5)
      .frame(minHeight: 20)
      .background(Palette.muted, in: RoundedRectangle(cornerRadius: 4))
      .outlined(radius: 4)
  }
}

/// A rounded-full chip with a hairline border: the storage badges and filters.
struct Pill<Content: View>: View {
  var height: CGFloat = 28
  var fill: Color = Palette.card
  @ViewBuilder var content: Content

  var body: some View {
    HStack(spacing: 6) { content }
      .font(.system(size: 12, weight: .medium))
      .padding(.horizontal, 10)
      .frame(height: height)
      .background(fill, in: Capsule())
      .overlay(Capsule().strokeBorder(Palette.border))
  }
}

/// shadcn's secondary Badge, such as the 3 / 100 next to a heading.
struct CountBadge: View {
  var text: String
  var body: some View {
    Text(text)
      .font(.system(size: 12, weight: .medium))
      .monospacedDigit()
      .padding(.horizontal, 8)
      .frame(height: 22)
      .background(Palette.muted, in: Capsule())
  }
}

/// Where the data is saved, as in the top bar and beside page headings (StorageBadge, PageStorageBadge).
struct StorageBadge: View {
  @Environment(AppModel.self) private var app
  var body: some View {
    Pill {
      Image(systemName: app.storage == .account ? "cloud" : "internaldrive").font(.system(size: 11)).foregroundStyle(Palette.mutedForeground)
      Text(app.storage == .account ? L("storage.account") : L("storage.local")).foregroundStyle(Palette.foreground.opacity(0.7))
    }
    .accessibilityElement(children: .combine)
  }
}

/// A round icon tile, like the monitor and language icons on the devices and settings cards.
struct IconTile: View {
  var systemName: String
  var size: CGFloat = 40
  var body: some View {
    Image(systemName: systemName)
      .font(.system(size: size * 0.42))
      .foregroundStyle(Palette.foreground.opacity(0.8))
      .frame(width: size, height: size)
      .background(Palette.muted, in: RoundedRectangle(cornerRadius: Radius.lg))
  }
}

/// The yellow rank circle of a best record.
struct RankBadge: View {
  var rank: Int
  var body: some View {
    Text("\(rank)")
      .font(.system(size: 12, weight: .bold))
      .monospacedDigit()
      .foregroundStyle(rank == 1 ? Palette.amber : Palette.mutedForeground)
      .frame(width: 22, height: 22)
      .background(rank == 1 ? Palette.amberSoft : Palette.muted, in: Circle())
  }
}

/// A number with its unit in a smaller, muted size: 「1.08 秒」.
struct ValueWithUnit: View {
  var value: String
  var unit: String
  var size: CGFloat = 28
  var weight: Font.Weight = .medium

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 2) {
      Text(value).font(.system(size: size, weight: weight)).monospacedDigit().foregroundStyle(Palette.foreground)
      if !unit.isEmpty { Text(unit).font(.system(size: max(12, size * 0.5))).foregroundStyle(Palette.mutedForeground) }
    }
  }
}
