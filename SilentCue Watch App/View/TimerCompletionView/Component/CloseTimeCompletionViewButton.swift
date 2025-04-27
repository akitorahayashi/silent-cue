import SwiftUI
import SCShared

struct CloseTimeCompletionViewButton: View {
    let action: () -> Void
    @Binding var appearAnimation: Bool

    var body: some View {
        Button(action: action) {
            Text("閉じる")
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10.5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                )
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(SCAccessibilityIdentifiers.TimerCompletionView.closeTimeCompletionViewButton.rawValue)
        .padding(.horizontal)
        .opacity(appearAnimation ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.4), value: appearAnimation)
    }
}

#Preview {
    CloseTimeCompletionViewButton(action: {}, appearAnimation: .constant(true))
}
