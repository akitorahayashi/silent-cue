import SCShared
import SwiftUI

struct StartButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Text("開始")
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                )
                .foregroundStyle(.primary)
        })
        .buttonStyle(.plain)
        .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue)
        .padding(.horizontal)
        .padding(.top, 12)
    }
}
