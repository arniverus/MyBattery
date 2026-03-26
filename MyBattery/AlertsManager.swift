import Foundation
import SwiftUI
import UserNotifications
import Combine

struct BatteryAlert: Identifiable, Codable {
    var id = UUID()
    var threshold: Int
    var type: AlertType
    var enabled: Bool = true

    enum AlertType: String, Codable {
        case lowBattery, charged, pluggedIn, unplugged
    }
}

class AlertsManager: NSObject, ObservableObject {
    static let shared = AlertsManager()

    @Published var lowBatteryAlerts: [BatteryAlert] = []
    @Published var chargedAlerts: [BatteryAlert] = []
    @Published var pluggedInEnabled: Bool = true
    @Published var unpluggedEnabled: Bool = true

    private var lastBatteryLevel: Int = -1
    private var lastChargingState: Bool? = nil
    private let defaults = UserDefaults.standard

    override init() {
        super.init()
        requestPermission()
        loadAlerts()

        if lowBatteryAlerts.isEmpty {
            lowBatteryAlerts = [
                BatteryAlert(threshold: 3, type: .lowBattery),
                BatteryAlert(threshold: 5, type: .lowBattery),
                BatteryAlert(threshold: 15, type: .lowBattery)
            ]
        }
        if chargedAlerts.isEmpty {
            chargedAlerts = [BatteryAlert(threshold: 80, type: .charged)]
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func check(batteryLevel: Int, isCharging: Bool, timeRemaining: String) {
        if let last = lastChargingState {
            if isCharging && !last && pluggedInEnabled {
                OverlayManager.shared.showCharging(
                    batteryLevel: batteryLevel,
                    minutesRemaining: timeRemaining
                )
            } else if !isCharging && last && unpluggedEnabled {
                OverlayManager.shared.showUnplugged(batteryLevel: batteryLevel)
            }
        }
        lastChargingState = isCharging

        if !isCharging {
            for alert in lowBatteryAlerts where alert.enabled {
                if lastBatteryLevel > alert.threshold && batteryLevel <= alert.threshold {
                    let glowColor: Color = alert.threshold <= 5 ? .red : .yellow
                    OverlayManager.shared.showLowBatteryGlow(
                        threshold: alert.threshold,
                        color: glowColor
                    )
                }
            }
        }

        if isCharging {
            for alert in chargedAlerts where alert.enabled {
                if lastBatteryLevel < alert.threshold && batteryLevel >= alert.threshold {
                    OverlayManager.shared.showCharging(
                        batteryLevel: batteryLevel,
                        minutesRemaining: "Charged to \(alert.threshold)%"
                    )
                }
            }
        }

        lastBatteryLevel = batteryLevel
    }

    func saveAlerts() {
        if let lowData = try? JSONEncoder().encode(lowBatteryAlerts) {
            defaults.set(lowData, forKey: "lowBatteryAlerts")
        }
        if let chargedData = try? JSONEncoder().encode(chargedAlerts) {
            defaults.set(chargedData, forKey: "chargedAlerts")
        }
        defaults.set(pluggedInEnabled, forKey: "pluggedInEnabled")
        defaults.set(unpluggedEnabled, forKey: "unpluggedEnabled")
    }

    func loadAlerts() {
        if let lowData = defaults.data(forKey: "lowBatteryAlerts"),
           let low = try? JSONDecoder().decode([BatteryAlert].self, from: lowData) {
            lowBatteryAlerts = low
        }
        if let chargedData = defaults.data(forKey: "chargedAlerts"),
           let charged = try? JSONDecoder().decode([BatteryAlert].self, from: chargedData) {
            chargedAlerts = charged
        }
        pluggedInEnabled = defaults.bool(forKey: "pluggedInEnabled")
        unpluggedEnabled = defaults.bool(forKey: "unpluggedEnabled")
    }
}
