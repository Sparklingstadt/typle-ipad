import SwiftUI
import TypleCore

/// Adding or editing a device (the web app's device dialog).
struct DeviceEditor: View {
  @Environment(AppModel.self) private var app
  @Environment(\.dismiss) private var dismiss
  let device: PracticeDevice?
  var onSaved: (String) -> Void
  @State private var name = ""
  @State private var layout = ""
  @State private var use = true
  @State private var problem: DeviceProblem?
  @State private var errorMessage: String?
  @State private var loaded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        Text(device == nil ? L("devices.dialog.addTitle") : L("devices.dialog.editTitle")).font(.system(size: 18, weight: .semibold))
        Text(device == nil ? L("devices.dialog.addDescription") : L("devices.dialog.editDescription")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
      }
      field(L("devices.dialog.name"), optional: false, placeholder: L("devices.dialog.namePlaceholder"), text: $name,
            help: L("devices.dialog.nameHelp"), error: problem?.field == .name ? problem.map { errorText($0.error) } : nil)
      field(L("devices.dialog.layout"), optional: true, placeholder: L("devices.dialog.layoutPlaceholder"), text: $layout,
            help: L("devices.dialog.layoutHelp"), error: problem?.field == .layout ? problem.map { errorText($0.error) } : nil)
      if device == nil {
        Toggle(isOn: $use) {
          VStack(alignment: .leading, spacing: 2) {
            Text(L("devices.dialog.use")).font(.system(size: 14, weight: .medium))
            Text(L("devices.dialog.useHelp")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
          }
        }
        .tint(Palette.primary)
      }
      if let errorMessage { Text(errorMessage).font(.system(size: 13)).foregroundStyle(Palette.destructive) }
      HStack {
        Spacer()
        Button(L("common.form.cancel")) { dismiss() }.buttonStyle(.typle(.outline, size: .lg))
        Button(device == nil ? L("common.form.add") : L("common.form.save")) { save() }.buttonStyle(.typle(.primary, size: .lg))
      }
    }
    .padding(24)
    .background(Palette.card)
    .sheetSize(width: 480)
    .presentationDetents([.medium])
    .onAppear {
      guard !loaded else { return }
      loaded = true
      name = device?.name ?? ""
      layout = device?.layout ?? ""
    }
  }

  private func field(_ label: String, optional: Bool, placeholder: String, text: Binding<String>, help: String, error: String?) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 2) {
        Text(label).font(.system(size: 14, weight: .semibold))
        if optional { Text(L("devices.dialog.optional")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground) }
      }
      InputBox(placeholder: placeholder, text: text, invalid: error != nil)
      Text(error ?? help).font(.system(size: 12)).foregroundStyle(error == nil ? Palette.mutedForeground : Palette.destructive)
    }
  }

  private func save() {
    let edited = PracticeDevice(id: device?.id ?? randomId(), name: name, layout: layout)
    problem = deviceProblem(app.devices, edited, editing: device != nil, defaultName: app.defaultDeviceName)
    errorMessage = problem?.field == .form ? problem.map { errorText($0.error) } : nil
    guard problem == nil else { return }
    Task {
      do {
        try await app.saveDevice(edited, editing: device != nil)
        if device == nil && use { app.chooseDevice(edited.id) }
        onSaved(edited.name.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
      } catch { errorMessage = errorText(error) }
    }
  }
}
