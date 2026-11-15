import SwiftUI
import TypleCore

@main
struct TypleApp: App {
  @State private var app = AppModel()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(app)
        .task { await app.reload() }
        #if os(macOS)
        // The smallest window the pages are laid out for: the top bar's parts and the practice card fit in it.
        .frame(minWidth: 800, minHeight: 560)
        #endif
        #if os(macOS) && DEBUG
        // Screenshots: `-TypleSnapshot <file>` saves the window and quits.
        .task { await MacSnapshot.takeIfAsked() }
        #endif
    }
    #if os(macOS)
    // As wide as the web app's sidebar layout, at the height of the web captures.
    .defaultSize(width: 1280, height: 820)
    .commands { TypleCommands(app: app) }
    #endif
  }
}
