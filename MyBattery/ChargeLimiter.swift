import Foundation
import SwiftUI
import Combine

class ChargeLimiter: NSObject, ObservableObject {
    static let shared = ChargeLimiter()

    var limitEnabled: Bool {
        didSet { objectWillChange.send(); save(); applyCurrentState() }
    }
    var limitPercentage: Int {
        didSet { objectWillChange.send(); save() }
    }

    private let defaults = UserDefaults.standard
    private var hasShownAlert = false

    override init() {
        limitEnabled = defaults.bool(forKey: "chargeLimitEnabled")
        let saved = defaults.integer(forKey: "chargeLimitPercentage")
        limitPercentage = saved == 0 ? 80 : saved
        super.init()
        syncFromBatt()
    }

    func save() {
        defaults.set(limitEnabled, forKey: "chargeLimitEnabled")
        defaults.set(limitPercentage, forKey: "chargeLimitPercentage")
    }

    func syncFromBatt() {
        DispatchQueue.global(qos: .background).async {
            let output = self.runBatt("status")
            DispatchQueue.main.async {
                if let range = output.range(of: #"Upper limit:\s+(\d+)%"#, options: .regularExpression) {
                    let match = String(output[range])
                    if let pct = match.components(separatedBy: CharacterSet.decimalDigits.inverted)
                        .filter({ !$0.isEmpty }).first,
                       let val = Int(pct), val < 100 {
                        self.limitEnabled = true
                        self.limitPercentage = val
                    }
                }
            }
        }
    }

    func applyCurrentState() {
        if limitEnabled {
            setBattLimit(limitPercentage)
        } else {
            disableBatt()
        }
    }

    func check(batteryLevel: Int) {
        guard limitEnabled else {
            hasShownAlert = false
            return
        }
        if batteryLevel >= limitPercentage && !hasShownAlert {
            hasShownAlert = true
            OverlayManager.shared.showChargeLimitReached(percentage: limitPercentage)
        }
        if batteryLevel < limitPercentage - 2 {
            hasShownAlert = false
        }
    }

    func setBattLimit(_ percentage: Int) {
        DispatchQueue.global(qos: .background).async {
            self.runBatt("limit \(percentage)")
        }
    }

    func disableBatt() {
        DispatchQueue.global(qos: .background).async {
            self.runBatt("limit 100")
        }
    }

    @discardableResult
    func runBatt(_ args: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/local/bin/batt"
        task.arguments = args.components(separatedBy: " ")
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
