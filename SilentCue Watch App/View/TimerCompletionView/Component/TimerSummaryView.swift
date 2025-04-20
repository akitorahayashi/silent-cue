import SwiftUI

struct TimerSummaryView: View {
    let startDate: Date?
    let timerDurationMinutes: Int
    @Binding var appearAnimation: Bool

    var body: some View {
        VStack {
            // 開始時刻
            if let startDate {
                VStack(spacing: 4) {
                    HStack {
                        Text("開始時刻")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    HStack {
                        Text(SCTimeFormatter.formatToHoursAndMinutes(startDate))
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()
                    .background(Color.primary.opacity(0.1))
                    .padding(.horizontal, 8)
            }

            // 使用時間
            VStack(spacing: 4) {
                HStack {
                    Text("タイマー時間")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                HStack {
                    Text("\(timerDurationMinutes)分")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SCAccessibilityIdentifiers.TimerCompletionView.timerSummaryViewVStack.rawValue)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
        .opacity(appearAnimation ? 1.0 : 0.0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeInOut(duration: 0.5).delay(0.3), value: appearAnimation)
    }
}

#Preview {
    @Previewable @State var appearAnimation = true
    return TimerSummaryView(
        startDate: Date(),
        timerDurationMinutes: 15,
        appearAnimation: $appearAnimation
    )
}
