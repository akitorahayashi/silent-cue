import SwiftUI

struct CancelButtonView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("キャンセル")
                .foregroundStyle(.primary)
                .font(.system(size: 16))
        }
        .accessibilityLabel("CancelTimerButton")
        .accessibilityIdentifier("CancelTimerButton")
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
