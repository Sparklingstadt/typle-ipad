import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The web app's design tokens (src/app/globals.css, shadcn's neutral theme), as colours that follow light and dark.
enum Palette {
  private static func color(_ light: UInt32, _ dark: UInt32, darkAlpha: CGFloat = 1) -> Color {
    #if canImport(UIKit)
    Color(UIColor { traits in
      traits.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkAlpha) : UIColor(hex: light)
    })
    #else
    Color(NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(hex: dark, alpha: darkAlpha) : NSColor(hex: light)
    })
    #endif
  }

  /// The top bar and the sidebar.
  static let background = color(0xFFFFFF, 0x0A0A0A)
  /// Behind the cards of a page.
  static let page = color(0xFAFAFA, 0x1A1A1A)
  static let card = color(0xFFFFFF, 0x171717)
  static let foreground = color(0x0A0A0A, 0xFAFAFA)
  static let primary = color(0x171717, 0xE5E5E5)
  static let primaryForeground = color(0xFAFAFA, 0x171717)
  static let muted = color(0xF5F5F5, 0x262626)
  static let mutedForeground = color(0x737373, 0xA1A1A1)
  static let accent = color(0xF5F5F5, 0x262626)
  static let border = color(0xE5E5E5, 0xFFFFFF, darkAlpha: 0.1)
  static let input = color(0xE5E5E5, 0xFFFFFF, darkAlpha: 0.15)
  static let ring = color(0xA1A1A1, 0x737373)
  static let destructive = color(0xE7000B, 0xFF6467)
  static let destructiveSoft = color(0xFEE2E2, 0x460809)
  /// Tailwind's green-700 / green-400, for good news.
  static let success = color(0x008236, 0x05DF72)
  static let successSoft = color(0xDCFCE7, 0x032E15)
  /// Tailwind's amber-100 / amber-950 behind a best record, with amber-800 / amber-300 text.
  static let amberSoft = color(0xFEF3C6, 0x461901)
  static let amber = color(0x973C00, 0xFFD230)
  static let amberBorder = color(0xFEE685, 0x7B3306)
  static let trend = color(0x2A78D6, 0x3987E5)
  static let pending = color(0xA1A1A1, 0x737373)
}

#if canImport(UIKit)
extension UIColor {
  convenience init(hex: UInt32, alpha: CGFloat = 1) {
    self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
  }
}
#else
extension NSColor {
  convenience init(hex: UInt32, alpha: CGFloat = 1) {
    self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
  }
}
#endif

/// Corner radii of `--radius` (10px) and its steps.
enum Radius {
  static let sm: CGFloat = 6
  static let md: CGFloat = 8
  static let lg: CGFloat = 10
  static let xl: CGFloat = 14
}

// MARK: Surfaces

extension View {
  /// shadcn's Card: the card colour, a hairline border and the xl radius.
  func card(radius: CGFloat = Radius.xl) -> some View {
    background(Palette.card, in: RoundedRectangle(cornerRadius: radius))
      .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Palette.border))
  }

  /// A bordered box without a fill, like `ring-1 ring-foreground/10`.
  func outlined(radius: CGFloat = Radius.xl, color: Color = Palette.border) -> some View {
    overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(color))
  }

  func hairline(_ edge: Edge) -> some View {
    overlay(alignment: edge == .top ? .top : edge == .bottom ? .bottom : edge == .leading ? .leading : .trailing) {
      if edge == .top || edge == .bottom {
        Rectangle().fill(Palette.border).frame(height: 1)
      } else {
        Rectangle().fill(Palette.border).frame(width: 1)
      }
    }
  }
}

/// A full-width hairline, the web's `border-t` between sections.
struct Hairline: View {
  var body: some View { Rectangle().fill(Palette.border).frame(height: 1) }
}
