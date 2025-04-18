import SwiftUI

struct CancelButtonView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Cancel", systemImage: "xmark")
                .labelStyle(.iconOnly)
                .foregroundStyle(Color.red)
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
        .buttonStyle(.plain)
        .background(Color.gray.opacity(0.2))
        .clipShape(Circle())
        .accessibilityLabel("Cancel Timer")
        .accessibilityIdentifier(SCAccessibilityIdentifiers.CountdownView.cancelTimerButton.rawValue)
    }
}
