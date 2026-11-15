import SwiftUI
import TypleCore

/// The device the run is recorded with (src/components/Practice/DeviceMenu.tsx). It cannot change while a run goes on.
struct DeviceMenu: View {
  @Environment(AppModel.self) private var app
  var current: PracticeDevice?
  var locked: Bool

  var body: some View {
    Menu {
      Section(L("practice.device.heading")) {
        ForEach([defaultDevice(name: app.defaultDeviceName)] + app.devices) { device in
          Button { app.chooseDevice(device.id) } label: {
            if device.id == current?.id { Label(Format.device(device), systemImage: "checkmark") } else { Text(Format.device(device)) }
          }
        }
        Button { app.chooseDevice("") } label: {
          if current == nil { Label(L("devices.none"), systemImage: "checkmark") } else { Text(L("devices.none")) }
        }
      }
      Divider()
      Button { app.navigate(.devices) } label: { Label(L("practice.device.manage"), systemImage: "desktopcomputer") }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "keyboard").font(.system(size: 12))
        Text(current.map { Format.device($0) } ?? L("devices.none")).lineLimit(1)
        Image(systemName: locked ? "lock" : "chevron.down").font(.system(size: 10, weight: .semibold))
      }
      .font(.system(size: 13, weight: .medium))
      .foregroundStyle(locked ? Palette.mutedForeground : Palette.foreground)
      .padding(.horizontal, 12)
      .frame(height: 32)
      .background(Palette.card, in: Capsule())
      .overlay(Capsule().strokeBorder(Palette.border))
    }
    .plainMenu()
    .disabled(locked)
    .accessibilityLabel(L("practice.device.label", current.map { Format.device($0) } ?? L("devices.none")))
  }
}
