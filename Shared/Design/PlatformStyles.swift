import SwiftUI

extension View {
  /// Text typed as it is: no capitals, corrections or the text field's own frame, which the parts draw themselves.
  func plainInput() -> some View {
    #if os(iOS)
    return textFieldStyle(.plain).textInputAutocapitalization(.never).autocorrectionDisabled()
    #else
    return textFieldStyle(.plain).autocorrectionDisabled()
    #endif
  }

  /// A menu that shows its label as it is drawn, as on the iPad. The Mac's menu button would draw its own frame.
  func plainMenu() -> some View {
    #if os(macOS)
    return menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
    #else
    return self
    #endif
  }

  /// A picker inside a menu, whose choices are the menu's items as on the iPad, not a submenu.
  func menuPicker() -> some View {
    #if os(macOS)
    return pickerStyle(.inline).labelsHidden()
    #else
    return self
    #endif
  }

  /// A sheet's size on the Mac, where a sheet is as large as its content; the iPad's sheets size themselves.
  func sheetSize(width: CGFloat, height: CGFloat? = nil) -> some View {
    #if os(macOS)
    return frame(width: width, height: height)
    #else
    return self
    #endif
  }
}
