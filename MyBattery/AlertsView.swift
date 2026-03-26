import SwiftUI

struct AlertsView: View {
    @ObservedObject var manager = AlertsManager.shared
    @State private var showingAddLow = false
    @State private var showingAddCharged = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Low Battery
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "battery.25")
                            .foregroundColor(.red)
                        Text("Low Battery Alerts")
                            .font(.headline)
                        Spacer()
                    }
                    Text("Notify when battery goes below percentage")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach($manager.lowBatteryAlerts) { $alert in
                        AlertRow(
                            icon: "battery.25",
                            iconColor: alert.threshold <= 5 ? .red : .yellow,
                            label: "\(alert.threshold)%",
                            subtitle: "Sound",
                            enabled: $alert.enabled,
                            onDelete: {
                                manager.lowBatteryAlerts.removeAll { $0.id == alert.id }
                                manager.saveAlerts()
                            }
                        )
                    }

                    Button(action: { showingAddLow = true }) {
                        Label("Add Low Battery Alert", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                // MARK: - Charged Alerts
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "battery.100.bolt")
                            .foregroundColor(.green)
                        Text("Charged Alerts")
                            .font(.headline)
                        Spacer()
                    }
                    Text("Notify when battery reaches percentage")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach($manager.chargedAlerts) { $alert in
                        AlertRow(
                            icon: "battery.100.bolt",
                            iconColor: .green,
                            label: "\(alert.threshold)%",
                            subtitle: "Sound",
                            enabled: $alert.enabled,
                            onDelete: {
                                manager.chargedAlerts.removeAll { $0.id == alert.id }
                                manager.saveAlerts()
                            }
                        )
                    }

                    Button(action: { showingAddCharged = true }) {
                        Label("Add Charged Alert", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                // MARK: - Power Source Alerts
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "powerplug.fill")
                            .foregroundColor(.orange)
                        Text("Power Source Alerts")
                            .font(.headline)
                        Spacer()
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Plugged In")
                                .fontWeight(.medium)
                            Text("Notify when power adapter is connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $manager.pluggedInEnabled)
                            .onChange(of: manager.pluggedInEnabled) { _, _ in
                                manager.saveAlerts()
                            }
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Unplugged")
                                .fontWeight(.medium)
                            Text("Notify when power adapter is disconnected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $manager.unpluggedEnabled)
                            .onChange(of: manager.unpluggedEnabled) { _, _ in
                                manager.saveAlerts()
                            }
                    }
                }
            }
            .padding()
        }
        .frame(width: 420, height: 560)
        .sheet(isPresented: $showingAddLow) {
            AddAlertSheet(title: "Add Low Battery Alert") { val in
                manager.lowBatteryAlerts.append(BatteryAlert(threshold: val, type: .lowBattery))
                manager.saveAlerts()
            }
        }
        .sheet(isPresented: $showingAddCharged) {
            AddAlertSheet(title: "Add Charged Alert") { val in
                manager.chargedAlerts.append(BatteryAlert(threshold: val, type: .charged))
                manager.saveAlerts()
            }
        }
    }
}

struct AlertRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let subtitle: String
    @Binding var enabled: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text(label).fontWeight(.semibold)
            Text("· \(subtitle)")
                .foregroundColor(.secondary)
                .font(.caption)
            Spacer()
            Toggle("", isOn: $enabled)
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AddAlertSheet: View {
    let title: String
    let onAdd: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var value: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.headline)
            TextField("Percentage (1-100)", text: $value)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Add") {
                    if let val = Int(value), val > 0, val <= 100 {
                        onAdd(val)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 260)
    }
}
