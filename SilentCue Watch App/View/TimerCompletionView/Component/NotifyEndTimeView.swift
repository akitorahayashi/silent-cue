import SCShared
import SwiftUI

struct NotifyEndTimeView: View {
    let completionDate: Date?
    @Binding var appearAnimation: Bool

    var body: some View {
        VStack {
            Image(systemName: "bell.and.waves.left.and.right")
                .font(.system(size: 40))
                .foregroundStyle(.primary)

            Spacer()
                .frame(height: 8)

            // キャプション
            Text("終了時刻")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            if let date = completionDate {
                Text(SCTimeFormatter.formatToHoursAndMinutes(date))
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
            } else {
                Text("00:00")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
            }
        }
        .opacity(appearAnimation ? 1.0 : 0.0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeInOut(duration: 0.5).delay(0.2), value: appearAnimation)
    }
}

#Preview {
    @Previewable @State var appearAnimation = true
    return NotifyEndTimeView(
        completionDate: Date(),
        appearAnimation: $appearAnimation
    )
}
