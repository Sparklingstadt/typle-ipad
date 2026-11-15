import SwiftUI
import TypleCore

/// The practice devices (src/app/(workspace)/devices/page.tsx): the device this iPad practises on, and the registered
/// ones. Through the API, devices can be chosen but not changed.
struct DevicesView: View {
  @Environment(AppModel.self) private var app
  @State private var editing: PracticeDevice?
  @State private var creating = false
  @State private var deleting: PracticeDevice?
  @State private var status: StatusMessage?

  var body: some View {
    let usage = deviceUsage(app.lists)
    let chosen = app.chosenPracticeDevice
    PageScroll(maxWidth: 832) {
      PageHeader(title: L("devices.title"), description: L("devices.description"))
      if let status { StatusLabel(status: status) }
      current(chosen)
      HStack {
        Text(L("devices.listHeading")).font(.system(size: 16, weight: .bold))
        if !app.devices.isEmpty { CountBadge(text: L("devices.count", app.devices.count)) }
        Spacer()
        if !app.devices.isEmpty {
          Button { creating = true } label: { Label(L("devices.add"), systemImage: "plus") }
            .buttonStyle(.typle(.primary, size: .lg))
            .disabled(app.devices.count >= maxDevices)
        }
      }
      .padding(.top, 8)
      VStack(spacing: 12) {
        row(defaultDevice(name: app.defaultDeviceName), usage: usage[defaultDeviceId], chosen: chosen?.id == defaultDeviceId,
            detail: L("devices.defaultDetail"), editable: false)
        ForEach(app.devices) { device in
          row(device, usage: usage[device.id], chosen: chosen?.id == device.id, detail: device.layout, editable: true)
        }
        if app.devices.isEmpty { empty }
      }
    }
    .sheet(isPresented: $creating) { DeviceEditor(device: nil) { status = .done(L("devices.added", $0)) } }
    .sheet(item: $editing) { device in DeviceEditor(device: device) { status = .done(L("devices.saved", $0)) } }
    .confirmationDialog(deleting.map { L("devices.deleteTitle", $0.name) } ?? "", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                        titleVisibility: .visible, presenting: deleting) { device in
      Button(L("common.delete.confirm"), role: .destructive) { delete(device) }
    } message: { device in
      let count = usage[device.id]?.count ?? 0
      Text(L("devices.deleteRemoval", device.name) + (count > 0 ? L("devices.deleteRecords", count) : L("devices.deleteNoRecords")))
    }
  }

  private func current(_ chosen: PracticeDevice?) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 16) {
        IconTile(systemName: "desktopcomputer")
        VStack(alignment: .leading, spacing: 2) {
          Text(L("devices.current.heading")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
          Text(chosen.map { Format.device($0) } ?? L("devices.choice.notSelected")).font(.system(size: 16, weight: .semibold))
        }
        Spacer()
        Menu {
          ForEach([defaultDevice(name: app.defaultDeviceName)] + app.devices) { device in
            Button { app.chooseDevice(device.id) } label: {
              if device.id == chosen?.id { Label(Format.device(device), systemImage: "checkmark") } else { Text(Format.device(device)) }
            }
          }
          Button { app.chooseDevice("") } label: {
            if chosen == nil { Label(L("devices.none"), systemImage: "checkmark") } else { Text(L("devices.none")) }
          }
        } label: {
          HStack(spacing: 6) { Text(L("devices.current.change")); Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold)) }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Palette.foreground)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.md))
            .outlined(radius: Radius.md)
        }
        .plainMenu()
        .accessibilityLabel(L("devices.current.changeLabel", chosen.map { Format.device($0) } ?? L("devices.choice.notSelected")))
        Button { app.navigate(.practice) } label: { Label(L("devices.current.practice"), systemImage: "keyboard") }
          .buttonStyle(.typle(.outline, size: .lg))
      }
      Text(chosen == nil ? L("devices.current.noteUnselected") : L("devices.current.noteSelected"))
        .font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
        .padding(.leading, 56)
    }
    .padding(20)
    .card()
  }

  private func row(_ device: PracticeDevice, usage: DeviceUsage?, chosen: Bool, detail: String, editable: Bool) -> some View {
    HStack(spacing: 16) {
      IconTile(systemName: "desktopcomputer")
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 8) {
          Text(device.id == defaultDeviceId ? app.defaultDeviceName : device.name).font(.system(size: 16, weight: .semibold))
          if chosen {
            HStack(spacing: 3) { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)); Text(L("devices.inUse")) }
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Palette.success)
              .padding(.horizontal, 8)
              .frame(height: 22)
              .background(Palette.successSoft, in: Capsule())
              .overlay(Capsule().strokeBorder(Palette.success.opacity(0.3)))
          }
        }
        if !detail.isEmpty { Text(detail).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground) }
      }
      Spacer()
      HStack(spacing: 4) {
        Image(systemName: "clock.arrow.circlepath").font(.system(size: 11))
        Text(usage.map { L("devices.usage", $0.count, parseDate($0.lastUsed).map { Format.day($0) } ?? "") } ?? L("devices.neverUsed"))
      }
      .font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
      if editable {
        Button { editing = device } label: { Image(systemName: "pencil").font(.system(size: 14)) }
          .buttonStyle(.typle(.ghost, size: .icon))
          .accessibilityLabel(L("devices.editLabel", device.name))
        Button { deleting = device } label: { Image(systemName: "trash").font(.system(size: 14)) }
          .buttonStyle(.typle(.ghost, size: .icon))
          .foregroundStyle(Palette.mutedForeground)
          .accessibilityLabel(L("devices.deleteLabel", device.name))
      }
    }
    .padding(20)
    .card()
    .contentShape(Rectangle())
    .onTapGesture { app.chooseDevice(device.id) }
    .accessibilityAddTraits(chosen ? .isSelected : [])
  }

  private var empty: some View {
    VStack(spacing: 12) {
      IconTile(systemName: "desktopcomputer", size: 48)
      Text(L("devices.empty.title")).font(.system(size: 16, weight: .semibold))
      Text(L("devices.empty.description")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground).multilineTextAlignment(.center).frame(maxWidth: 360)
      Button { creating = true } label: { Label(L("devices.add"), systemImage: "plus") }.buttonStyle(.typle(.primary, size: .lg))
      Text(L("devices.empty.example")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
    }
    .frame(maxWidth: .infinity)
    .padding(40)
    .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.xl))
    .overlay(RoundedRectangle(cornerRadius: Radius.xl).strokeBorder(Palette.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
  }

  private func delete(_ device: PracticeDevice) {
    Task {
      status = await .of {
        try await app.deleteDevice(id: device.id)
        return L("devices.deleted", device.name)
      }
    }
  }
}
