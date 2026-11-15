import SwiftUI
import TypleCore

/// The web app's layout (src/app/layout.tsx): a 56pt top bar, and below it the sidebar beside the page when the
/// window is at least 1280pt wide, or a drawer opened from the menu button when it is narrower.
struct RootView: View {
  @Environment(AppModel.self) private var app
  @Environment(\.colorScheme) private var systemScheme
  @State private var drawerOpen = false

  var body: some View {
    GeometryReader { proxy in
      let wide = proxy.size.width >= 1280
      VStack(spacing: 0) {
        TopBar(showsMenu: !wide, onMenu: { withAnimation(.easeOut(duration: 0.2)) { drawerOpen = true } })
        HStack(spacing: 0) {
          if wide {
            ScrollView { NavList(onNavigate: {}).padding(12) }
              .frame(width: 240)
              .background(Palette.background)
              .hairline(.trailing)
          }
          page.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .overlay(alignment: .leading) {
        if drawerOpen && !wide {
          ZStack(alignment: .leading) {
            Color.black.opacity(0.5).ignoresSafeArea()
              .onTapGesture { closeDrawer() }
              .accessibilityLabel(L("nav.closeMenu"))
              .accessibilityAddTraits(.isButton)
            Drawer(onClose: closeDrawer)
              .frame(width: 288)
              .transition(.move(edge: .leading))
          }
        }
      }
    }
    .background(Palette.background)
    .tint(Palette.primary)
    .foregroundStyle(Palette.foreground)
    .environment(\.locale, app.language.locale)
    .preferredColorScheme(app.appearance == .system ? nil : app.appearance == .dark ? .dark : .light)
    // Text comes from the chosen language's bundle, so the whole tree is rebuilt when it changes.
    .id(app.language)
  }

  private func closeDrawer() {
    withAnimation(.easeOut(duration: 0.2)) { drawerOpen = false }
  }

  @ViewBuilder
  private var page: some View {
    if app.route == .general {
      // Settings stay reachable when the data cannot be read, to switch where it is kept.
      GeneralSettingsView()
    } else if app.document == nil {
      if let error = app.loadError {
        PageScroll {
          VStack(alignment: .leading, spacing: 12) {
            Label(L("errors.loadFailed"), systemImage: "exclamationmark.triangle").font(.headline).foregroundStyle(Palette.destructive)
            Text(error).font(.system(size: 14))
            HStack {
              Button(L("common.retry")) { Task { await app.reload() } }.buttonStyle(.typle())
              Button(L("nav.links.general")) { app.navigate(.general) }.buttonStyle(.typle(.outline))
            }
          }
          .padding(24)
          .card()
        }
      } else {
        ProgressView(L("common.loading")).frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.page)
      }
    } else {
      switch app.route {
      case .home: HomeView()
      case .practice: PracticeView()
      case .records: RecordsView()
      case .rankings: RankingsView()
      case .lists: ListsView()
      case .createList: ListEditorView(listId: nil)
      case .editList(let id): ListEditorView(listId: id).id(id)
      case .general: GeneralSettingsView()
      case .devices: DevicesView()
      }
    }
  }
}
