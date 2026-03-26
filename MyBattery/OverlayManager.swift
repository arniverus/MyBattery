import SwiftUI
import AppKit

// MARK: - HUD Pill Overlay
class HUDOverlayWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 64),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func show(icon: String, iconColor: Color, title: String, subtitle: String) {
        let view = HUDPillView(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
        self.contentView = NSHostingView(rootView: view)

        if let screen = NSScreen.main {
            let x = screen.frame.midX - 160
            let y = screen.frame.midY + 60
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.alphaValue = 0
        self.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            self.animator().alphaValue = 1
        }, completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.4
                    self.animator().alphaValue = 0
                }, completionHandler: {
                    self.orderOut(nil)
                })
            }
        })
    }
}

struct HUDPillView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(width: 320, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(white: 0.12).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Screen Glow Overlay
class GlowOverlayWindow: NSWindow {
    init() {
        guard let screen = NSScreen.main else {
            super.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
            return
        }
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func show(color: Color) {
        let view = GlowBorderView(color: color)
        self.contentView = NSHostingView(rootView: view)

        self.alphaValue = 0
        self.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.4
            self.animator().alphaValue = 1
        }, completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.6
                    self.animator().alphaValue = 0
                }, completionHandler: {
                    self.orderOut(nil)
                })
            }
        })
    }
}

struct GlowBorderView: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [color.opacity(0.9), color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 18
                    )
                    .blur(radius: 12)
                    .padding(4)

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.7), lineWidth: 6)
                    .padding(4)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Overlay Manager
class OverlayManager {
    static let shared = OverlayManager()
    private let hudWindow = HUDOverlayWindow()
    private let glowWindow = GlowOverlayWindow()

    func showCharging(batteryLevel: Int, minutesRemaining: String) {
        DispatchQueue.main.async {
            self.hudWindow.show(
                icon: "bolt.fill",
                iconColor: .green,
                title: "Charging",
                subtitle: "\(minutesRemaining) until full"
            )
        }
    }

    func showUnplugged(batteryLevel: Int) {
        DispatchQueue.main.async {
            self.hudWindow.show(
                icon: "minus",
                iconColor: .white,
                title: "On Battery",
                subtitle: "\(batteryLevel)% remaining"
            )
        }
    }

    func showLowBatteryGlow(threshold: Int, color: Color = .yellow) {
        DispatchQueue.main.async {
            self.glowWindow.show(color: color)
            self.hudWindow.show(
                icon: "battery.25",
                iconColor: color,
                title: "\(threshold)% Remaining",
                subtitle: "Soon until empty"
            )
        }
    }

    func showChargeLimitReached(percentage: Int) {
        DispatchQueue.main.async {
            self.glowWindow.show(color: .orange)
            self.hudWindow.show(
                icon: "bolt.slash.fill",
                iconColor: .orange,
                title: "Charge Limit Reached",
                subtitle: "Unplug to protect battery health"
            )
        }
    }
}
