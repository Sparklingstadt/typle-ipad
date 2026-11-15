import SwiftUI
import TypleCore

/// The sidebar's contents, shared by the wide layout and the drawer (src/components/Sidebar/NavList.tsx).
struct NavList: View {
  @Environment(AppModel.self) private var app
  @Environment(\.openURL) private var openURL
  var onNavigate: () -> Void

  private struct Item {
    var route: Route?
    var url: String?
    var title: String
    var icon: String
  }

  private var groups: [(String?, [Item])] {
    [
      (nil, [Item(route: .home, title: L("nav.links.home"), icon: "house")]),
      (L("nav.groups.practice"), [
        Item(route: .practice, title: L("nav.links.play"), icon: "keyboard"),
        Item(route: .records, title: L("nav.links.records"), icon: "clock.arrow.circlepath"),
        Item(route: .rankings, title: L("nav.links.rankings"), icon: "trophy"),
      ]),
      (L("nav.groups.wordLists"), [
        Item(route: .lists, title: L("nav.links.edit"), icon: "list.bullet"),
        Item(route: .createList, title: L("nav.links.create"), icon: "plus"),
      ]),
      (L("nav.groups.settings"), [
        Item(route: .general, title: L("nav.links.general"), icon: "gearshape"),
        Item(route: .devices, title: L("nav.links.devices"), icon: "desktopcomputer"),
      ]),
    ]
  }

  private var help: [Item] {
    [
      Item(url: "https://typle-r-six.vercel.app/guide", title: L("nav.links.guide"), icon: "book"),
      Item(url: "https://typle-r-six.vercel.app/about", title: L("nav.links.about"), icon: "info.circle"),
      Item(url: "https://github.com/Sparklingstadt/typle-r", title: "GitHub", icon: "arrow.up.right.square"),
    ]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(groups.indices, id: \.self) { index in
          if let label = groups[index].0 { groupLabel(label) }
          VStack(spacing: 2) {
            ForEach(groups[index].1.indices, id: \.self) { item in row(groups[index].1[item]) }
          }
        }
      }
      Spacer(minLength: 24)
      VStack(alignment: .leading, spacing: 0) {
        Hairline().padding(.bottom, 4)
        groupLabel(L("nav.help"))
        VStack(spacing: 2) { ForEach(help.indices, id: \.self) { row(help[$0]) } }
      }
    }
  }

  private func groupLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.mutedForeground)
      .padding(.horizontal, 12).padding(.top, 16).padding(.bottom, 4)
      .accessibilityAddTraits(.isHeader)
  }

  private func row(_ item: Item) -> some View {
    let current = item.route != nil && item.route == app.route.navigationItem
    return Button {
      if let route = item.route { app.navigate(route) } else if let url = item.url.flatMap(URL.init(string:)) { openURL(url) }
      onNavigate()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: item.icon).font(.system(size: 15)).frame(width: 18)
          .foregroundStyle(current ? Palette.foreground : Palette.mutedForeground)
        Text(item.title).font(.system(size: 14, weight: current ? .medium : .regular)).lineLimit(1)
          .foregroundStyle(current ? Palette.foreground : Palette.foreground.opacity(0.8))
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 12)
      .frame(height: 40)
      .background(current ? Palette.accent : .clear, in: RoundedRectangle(cornerRadius: Radius.md))
      .overlay(alignment: .leading) {
        if current { Capsule().fill(Palette.primary).frame(width: 3).padding(.vertical, 10) }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(current ? .isSelected : [])
  }
}
