import SwiftUI

struct CloseButtonView: View {
    let action: () -> Void
    @Binding var appearAnimation: Bool

    var body: some View {
        Button(action: action) {
            Text("閉じる")
                .font(.system(size: 16, weight: .medium))
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
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .opacity(appearAnimation ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.4), value: appearAnimation)
    }
}
