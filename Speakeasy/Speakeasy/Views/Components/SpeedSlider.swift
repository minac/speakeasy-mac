import SwiftUI

struct SpeedSlider: View {
    @Binding var speed: Float

    private let minSpeed: Float = 0.5
    private let maxSpeed: Float = 2.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Speed")
                Spacer()
                Text(speedText)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Slider(value: $speed, in: minSpeed...maxSpeed, step: 0.1) {
                Text("Speed")
            } minimumValueLabel: {
                Text("\(minSpeed, specifier: "%.1f")x")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Text("\(maxSpeed, specifier: "%.1f")x")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var speedText: String {
        String(format: "%.1fx", speed)
    }
}
