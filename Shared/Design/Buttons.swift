import SwiftUI

/// shadcn's Button variants and sizes.
struct TypleButtonStyle: ButtonStyle {
  enum Variant { case primary, outline, ghost, secondary, destructive }
  enum Size { case sm, regular, lg, icon, iconLg }

  var variant: Variant = .primary
  var size: Size = .regular
  @Environment(\.isEnabled) private var enabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: size == .sm ? 13 : 14, weight: .medium))
      .labelStyle(TightLabelStyle())
      .foregroundStyle(foreground)
      .padding(.horizontal, horizontalPadding)
      .frame(minWidth: isIcon ? height : nil, minHeight: height)
      .background(background(pressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: Radius.md))
      .overlay {
        if variant == .outline { RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.border) }
      }
      .contentShape(RoundedRectangle(cornerRadius: Radius.md))
      .opacity(enabled ? 1 : 0.5)
  }

  private var isIcon: Bool { size == .icon || size == .iconLg }
  private var height: CGFloat {
    switch size {
    case .sm: return 32
    case .regular, .icon: return 36
    case .lg, .iconLg: return 40
    }
  }
  private var horizontalPadding: CGFloat { isIcon ? 0 : size == .sm ? 10 : size == .lg ? 16 : 12 }

  private var foreground: Color {
    switch variant {
    case .primary: return Palette.primaryForeground
    case .destructive: return .white
    default: return Palette.foreground
    }
  }

  private func background(pressed: Bool) -> Color {
    switch variant {
    case .primary: return pressed ? Palette.primary.opacity(0.85) : Palette.primary
    case .destructive: return pressed ? Palette.destructive.opacity(0.85) : Palette.destructive
    case .secondary: return Palette.muted
    case .outline: return pressed ? Palette.accent : Palette.card
    case .ghost: return pressed ? Palette.accent : .clear
    }
  }
}

extension ButtonStyle where Self == TypleButtonStyle {
  static func typle(_ variant: TypleButtonStyle.Variant = .primary, size: TypleButtonStyle.Size = .regular) -> TypleButtonStyle {
    TypleButtonStyle(variant: variant, size: size)
  }
}

/// An icon and its title with the web's 6–8px gap.
struct TightLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 6) {
      configuration.icon.imageScale(.small)
      configuration.title
    }
  }
}
