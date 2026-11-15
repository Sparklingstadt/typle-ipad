import SwiftUI
import TypleCore

/// The top bar (src/components/Navbar): menu button when narrow, the brand, and on the right where data is saved,
/// the light and dark switch and the account.
struct TopBar: View {
  @Environment(AppModel.self) private var app
  @Environment(\.colorScheme) private var scheme
  var showsMenu: Bool
  var onMenu: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      if showsMenu {
        Button(action: onMenu) { Image(systemName: "line.3.horizontal").font(.system(size: 18)) }
          .buttonStyle(.typle(.ghost, size: .iconLg))
          .accessibilityLabel(L("nav.openMenu"))
      }
      Brand { app.navigate(.home) }
      Spacer(minLength: 8)
      StorageBadge()
      Button {
        app.setAppearance(scheme == .dark ? .light : .dark)
      } label: {
        Image(systemName: scheme == .dark ? "moon" : "sun.max").font(.system(size: 18))
      }
      .buttonStyle(.typle(.ghost, size: .iconLg))
      .accessibilityLabel(L("nav.theme.label"))
      .accessibilityValue(L(scheme == .dark ? "nav.theme.toLight" : "nav.theme.toDark"))
      AccountButton()
    }
    .padding(.horizontal, 12)
    .frame(height: 56)
    .background(Palette.background)
    .hairline(.bottom)
  }
}

/// The black keyboard tile and 「Typle」 (src/components/Navbar/Brand.tsx).
struct Brand: View {
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: "keyboard")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(Palette.primaryForeground)
          .frame(width: 28, height: 28)
          .background(Palette.primary, in: RoundedRectangle(cornerRadius: 7))
        Text("Typle").font(.system(size: 18, weight: .bold)).foregroundStyle(Palette.foreground)
      }
      .padding(.horizontal, 4)
      .frame(height: 40)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(L("nav.links.home"))
  }
}

/// The web app's GitHub login button. In the apps the login is in 一般, with where the data is kept.
struct AccountButton: View {
  @Environment(AppModel.self) private var app
  var body: some View {
    if app.storage == .account {
      Button { app.navigate(.general) } label: {
        Image(systemName: "person.fill").font(.system(size: 14))
          .foregroundStyle(Palette.mutedForeground)
          .frame(width: 32, height: 32)
          .background(Palette.muted, in: Circle())
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 4)
      .accessibilityLabel(L("account.connected"))
    } else {
      Button { app.navigate(.general) } label: {
        Label(L("account.connect"), systemImage: "rectangle.portrait.and.arrow.right")
      }
      .buttonStyle(.typle(.outline, size: .lg))
    }
  }
}
