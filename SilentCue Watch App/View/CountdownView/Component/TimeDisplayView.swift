import SwiftUI
import SCShared

struct TimeDisplayView: View {
    let displayTime: String
    let remainingSeconds: Int

    var body: some View {
        VStack {
            Text(remainingSeconds >= 3600 ? "時間  :  分" : "分  :  秒")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .accessibilityLabel(SCAccessibilityIdentifiers.CountdownView.timeFormatLabel.rawValue)
                .accessibilityIdentifier(SCAccessibilityIdentifiers.CountdownView.timeFormatLabel.rawValue)

            Text(displayTime)
                .font(.system(size: 40, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
                .accessibilityLabel(SCAccessibilityIdentifiers.CountdownView.countdownTimeDisplay.rawValue)
                .accessibilityIdentifier(SCAccessibilityIdentifiers.CountdownView.countdownTimeDisplay.rawValue)
        }
    }
}
