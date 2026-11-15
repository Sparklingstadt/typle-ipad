import SwiftUI
import TypleCore

/// The narrow layout's sidebar, sliding in from the left (src/components/Navbar/MobileNav.tsx).
struct Drawer: View {
  @Environment(AppModel.self) private var app
  var onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Brand { app.navigate(.home); onClose() }
        Spacer()
        Button(action: onClose) { Image(systemName: "xmark").font(.system(size: 16)) }
          .buttonStyle(.typle(.ghost, size: .icon))
          .accessibilityLabel(L("nav.closeMenu"))
      }
      .padding(.horizontal, 4)
      StorageBadge().padding(.leading, 0)
      ScrollView { NavList(onNavigate: onClose) }
    }
    .padding(12)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Palette.background)
    .shadow(color: .black.opacity(0.15), radius: 12, x: 4)
  }
}
