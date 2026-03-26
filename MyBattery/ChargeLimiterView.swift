import SwiftUI

struct ChargeLimiterView: View {
    @ObservedObject var limiter = ChargeLimiter.shared
    @State private var sliderValue: Double = 80
    @State private var isApplying: Bool = false
    @State private var statusMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // MARK: - Header
            HStack {
                Image(systemName: "bolt.slash.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Charge Limiter")
                        .font(.headline)
                    Text("Powered by batt daemon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $limiter.limitEnabled)
            }

            Divider()

            // MARK: - Limit Slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Charge Limit")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(sliderValue))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(colorForLimit(Int(sliderValue)))
                        .monospacedDigit()
                }

                Slider(value: $sliderValue, in: 50...100, step: 1)
                    .tint(colorForLimit(Int(sliderValue)))
                    .disabled(!limiter.limitEnabled)
                    .onChange(of: sliderValue) { _, newVal in
                        limiter.limitPercentage = Int(newVal)
                    }

                HStack {
                    Text("50%").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("80%").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("100%").font(.caption).foregroundColor(.secondary)
                }

                // Quick presets
                HStack(spacing: 8) {
                    ForEach([70, 75, 80, 85, 90], id: \.self) { preset in
                        Button("\(preset)%") {
                            sliderValue = Double(preset)
                            limiter.limitPercentage = preset
                            applyLimit(preset)
                        }
                        .buttonStyle(.bordered)
                        .tint(Int(sliderValue) == preset ? colorForLimit(preset) : .secondary)
                        .disabled(!limiter.limitEnabled)
                    }
                }
            }
            .opacity(limiter.limitEnabled ? 1.0 : 0.4)

            Divider()

            // MARK: - Apply Button
            HStack {
                VStack(alignment: .leading) {
                    if isApplying {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text("Applying...").font(.caption).foregroundColor(.secondary)
                        }
                    } else if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text(limiter.limitEnabled
                             ? "Limit active at \(limiter.limitPercentage)%"
                             : "Charge limiting is off")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: { applyLimit(Int(sliderValue)) }) {
                    Text("Apply")
                        .fontWeight(.semibold)
                        .frame(width: 70)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!limiter.limitEnabled || isApplying)
            }

            Text("ⓘ Changes take up to 2 minutes to reflect. batt runs in the background even when this app is closed.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 360, height: 320)
        .onAppear {
            sliderValue = Double(limiter.limitPercentage)
        }
    }

    func applyLimit(_ percentage: Int) {
        guard limiter.limitEnabled else { return }
        isApplying = true
        statusMessage = ""
        DispatchQueue.global(qos: .background).async {
            ChargeLimiter.shared.setBattLimit(percentage)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isApplying = false
                statusMessage = "Applied \(percentage)% limit ✓"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    statusMessage = ""
                }
            }
        }
    }

    func colorForLimit(_ value: Int) -> Color {
        if value <= 70 { return .green }
        else if value <= 85 { return .orange }
        else { return .red }
    }
}
