import SwiftUI

struct CompletionDetailsView: View {
    let completionDate: Date?
    @Binding var appearAnimation: Bool

    var body: some View {
        VStack {
            Image(systemName: "bell.and.waves.left.and.right")
                .font(.system(size: 40))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            // キャプション
            Text("終了時刻")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            if let completionDate {
                Text(SCTimeFormatter.formatToHoursAndMinutes(completionDate))
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .opacity(appearAnimation ? 1.0 : 0.0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeInOut(duration: 0.5).delay(0.2), value: appearAnimation)
    }
}
