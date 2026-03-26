import SwiftUI
import Combine
import IOKit.ps
import IOKit

struct ContentView: View {
    @State private var batteryLevel: Int = 0
    @State private var isCharging: Bool = false
    @State private var timeRemaining: String = "--"
    @State private var cycleCount: Int = 0
    @State private var condition: String = "Normal"
    @State private var maxCapacity: Int = 100
    @State private var temperature: Double = 0
    @State private var voltage: Double = 0
    @State private var current: Int = 0
    @State private var remaining: Int = 0
    @State private var currentFull: Int = 0
    @State private var designCapacity: Int = 0

    @ObservedObject var limiter = ChargeLimiter.shared

    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var batteryColor: Color {
        if batteryLevel > 50 { return .green }
        else if batteryLevel > 20 { return .yellow }
        else { return .red }
    }

    var healthColor: Color {
        if maxCapacity > 80 { return .green }
        else if maxCapacity > 60 { return .yellow }
        else { return .red }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // MARK: - Top Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(batteryLevel)")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(batteryColor)
                        Text("%")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(batteryColor)
                            .padding(.bottom, 10)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(isCharging ? "UNTIL FULL" : "REMAINING")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(timeRemaining)
                                .font(.system(size: 20, weight: .bold))
                        }
                    }

                    HStack {
                        Image(systemName: isCharging ? "bolt.fill" : "minus")
                            .foregroundColor(isCharging ? .yellow : .secondary)
                        Text(isCharging ? "Charging" : "On Battery")
                            .fontWeight(.medium)
                        Spacer()
                        Button(action: openChargeLimiterWindow) {
                            Image(systemName: "bolt.slash")
                                .foregroundColor(limiter.limitEnabled ? .orange : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Charge Limiter")

                        Button(action: openAlertsWindow) {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Alerts & Settings")
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(batteryColor)
                                .frame(width: geo.size.width * CGFloat(batteryLevel) / 100, height: 8)
                        }
                    }
                    .frame(height: 8)

                    // Charge limit indicator
                    if limiter.limitEnabled {
                        HStack {
                            Image(systemName: "bolt.slash.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Charge limit set to \(limiter.limitPercentage)%")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)

                // MARK: - Battery Health
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("Battery Health").fontWeight(.semibold)
                        Spacer()
                    }
                    HStack(alignment: .bottom) {
                        Text("\(maxCapacity)%")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(healthColor)
                        Text(condition)
                            .foregroundColor(healthColor)
                            .padding(.bottom, 3)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(cycleCount)/1000")
                                .fontWeight(.semibold)
                            Text("Cycle Count")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    ProgressView(value: Double(maxCapacity), total: 100)
                        .tint(healthColor)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)

                // MARK: - Temperature
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("Temperature").fontWeight(.semibold)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "thermometer.medium").foregroundColor(.green)
                        Text(String(format: "%.1f°C", temperature))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                        Spacer()
                        VStack(alignment: .trailing) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Normal").foregroundColor(.green).fontWeight(.medium)
                            }
                            Text("Optimal performance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text(String(format: "%.1f°F", temperature * 9 / 5 + 32))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)

                // MARK: - Power & Electrical
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "bolt.circle.fill").foregroundColor(.green)
                        Text("Power & Electrical").fontWeight(.semibold)
                        Spacer()
                    }
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Power Usage").font(.caption).foregroundColor(.secondary)
                            Text(String(format: "%.1f W", Double(current) * voltage / 1000.0))
                                .font(.system(size: 20, weight: .bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Voltage").font(.caption).foregroundColor(.secondary)
                            Text(String(format: "%.2f V", voltage))
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current").font(.caption).foregroundColor(.secondary)
                            Text("\(current) mA")
                                .font(.system(size: 20, weight: .bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            HStack {
                                Image(systemName: "bolt.fill").foregroundColor(.green).font(.caption)
                                Text(isCharging ? "Charging" : "Discharging").foregroundColor(.green)
                            }
                            Text("Normal voltage").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)

                // MARK: - Capacity Details
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "battery.100").foregroundColor(.blue)
                        Text("Capacity Details").fontWeight(.semibold)
                        Spacer()
                    }
                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text("\(remaining) mAh").foregroundColor(.green).fontWeight(.medium)
                    }
                    Divider()
                    HStack {
                        Text("Current Full")
                        Spacer()
                        Text("\(currentFull) mAh").foregroundColor(.green).fontWeight(.medium)
                    }
                    Divider()
                    HStack {
                        Text("Design Capacity")
                        Spacer()
                        Text("\(designCapacity) mAh").foregroundColor(.secondary).fontWeight(.medium)
                    }
                    Text("ⓘ We refresh your battery health stats every 30 sec")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top, 10)
        }
        .frame(width: 300, height: 600)
        .onAppear { refreshBattery() }
        .onReceive(timer) { _ in refreshBattery() }
    }

    func openAlertsWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Alerts"
        window.contentView = NSHostingView(rootView: AlertsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openChargeLimiterWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Charge Limiter"
        window.contentView = NSHostingView(rootView: ChargeLimiterView())
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Data Fetching
    func refreshBattery() {
        fetchPmset()
        fetchIOKit()
        AlertsManager.shared.check(
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            timeRemaining: timeRemaining
        )
    }

    func fetchPmset() {
        let output = shell("pmset -g batt")
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("InternalBattery") {
                if let percentRange = line.range(of: #"\d+%"#, options: .regularExpression) {
                    let percentStr = line[percentRange].replacingOccurrences(of: "%", with: "")
                    batteryLevel = Int(percentStr) ?? 0
                }
                isCharging = line.contains("charging") && !line.contains("discharging")
                if let timeRange = line.range(of: #"\d+:\d+"#, options: .regularExpression) {
                    let timeStr = String(line[timeRange])
                    let parts = timeStr.components(separatedBy: ":")
                    if let hours = Int(parts[0]), let mins = Int(parts[1]) {
                        timeRemaining = hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
                    }
                } else {
                    timeRemaining = "--"
                }
            }
        }
    }

    func fetchIOKit() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else {
            fetchSystemProfiler()
            return
        }
        defer { IOObjectRelease(service) }

        func ioInt(_ key: String) -> Int {
            guard let cfVal = IORegistryEntryCreateCFProperty(
                service, key as CFString, kCFAllocatorDefault, 0)
            else { return 0 }
            return (cfVal.takeRetainedValue() as? Int) ?? 0
        }

        let rawTemp      = ioInt("Temperature")
        let rawVoltage   = ioInt("Voltage")
        let rawCurrent   = ioInt("InstantAmperage")
        let rawDesign    = ioInt("DesignCapacity")
        let rawFull      = ioInt("AppleRawMaxCapacity")
        let rawRemaining = ioInt("AppleRawCurrentCapacity")
        let rawCycles    = ioInt("CycleCount")

        if rawTemp > 0 { temperature = Double(rawTemp) / 100.0 }
        if rawVoltage > 0 { voltage = Double(rawVoltage) / 1000.0 }
        current = abs(rawCurrent)
        if rawCycles > 0 { cycleCount = rawCycles }
        if rawDesign > 0 { designCapacity = rawDesign }
        if rawFull > 0 { currentFull = rawFull }
        if rawRemaining > 0 { remaining = rawRemaining }

        if rawDesign > 0 && rawFull > 0 {
            maxCapacity = min(Int((Double(rawFull) / Double(rawDesign)) * 100), 100)
        }

        if cycleCount == 0 { fetchSystemProfiler() }
    }

    func fetchSystemProfiler() {
        let output = shell("system_profiler SPPowerDataType")
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("Cycle Count:") {
                let val = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0"
                if cycleCount == 0 { cycleCount = Int(val) ?? 0 }
            }
            if line.contains("Condition:") {
                condition = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Normal"
            }
            if line.contains("Maximum Capacity:") && designCapacity == 0 {
                let val = line.components(separatedBy: ":").last?
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "%", with: "") ?? "100"
                maxCapacity = Int(val) ?? 100
            }
        }
    }

    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
