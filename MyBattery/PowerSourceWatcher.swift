import Foundation
import IOKit.ps
import IOKit

class PowerSourceWatcher {
    static let shared = PowerSourceWatcher()
    private var lastChargingState: Bool? = nil
    private var runLoopSource: CFRunLoopSource?

    func start() {
        let context = UnsafeMutableRawPointer(
            Unmanaged.passRetained(self).toOpaque()
        )

        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let ctx = context else { return }
            let watcher = Unmanaged<PowerSourceWatcher>
                .fromOpaque(ctx)
                .takeUnretainedValue()
            watcher.powerSourceChanged()
        }, context)?.takeRetainedValue() else { return }

        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)

        lastChargingState = currentlyCharging()
    }

    func powerSourceChanged() {
        let isCharging = currentlyCharging()
        let batteryLevel = currentBatteryLevel()

        DispatchQueue.main.async {
            if let last = self.lastChargingState {
                if isCharging && !last {
                    if AlertsManager.shared.pluggedInEnabled {
                        OverlayManager.shared.showCharging(
                            batteryLevel: batteryLevel,
                            minutesRemaining: self.timeRemaining()
                        )
                    }
                } else if !isCharging && last {
                    if AlertsManager.shared.unpluggedEnabled {
                        OverlayManager.shared.showUnplugged(batteryLevel: batteryLevel)
                    }
                }
            }
            self.lastChargingState = isCharging

            if isCharging {
                ChargeLimiter.shared.check(batteryLevel: batteryLevel)
            }
        }
    }

    func currentlyCharging() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)
                .takeUnretainedValue() as? [String: Any] {
                if let state = info[kIOPSPowerSourceStateKey] as? String {
                    return state == kIOPSACPowerValue
                }
            }
        }
        return false
    }

    func currentBatteryLevel() -> Int {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)
                .takeUnretainedValue() as? [String: Any] {
                return info[kIOPSCurrentCapacityKey] as? Int ?? 0
            }
        }
        return 0
    }

    func timeRemaining() -> String {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)
                .takeUnretainedValue() as? [String: Any] {
                let minutes = info[kIOPSTimeToFullChargeKey] as? Int ?? -1
                if minutes > 0 {
                    let h = minutes / 60
                    let m = minutes % 60
                    return h > 0 ? "\(h)h \(m)m" : "\(m)m"
                }
            }
        }
        return "--"
    }
}
