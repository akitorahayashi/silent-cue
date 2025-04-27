import SwiftUI
import SCShared

struct TimerModeSelectionButton: View {
    let mode: TimerMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(mode.rawValue)
                .font(.system(size: 14))
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected ?
                                Color.secondary.opacity(0.3) :
                                Color.secondary.opacity(0.1)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                )
                .foregroundStyle(Color.primary)
        }
        .accessibilityIdentifier(
            mode == TimerMode.minutes ?
                SCAccessibilityIdentifiers.SetTimerView.minutesModeButton.rawValue :
                SCAccessibilityIdentifiers.SetTimerView.timeModeButton.rawValue
        )
        .buttonStyle(.plain)
    }
}
