import SwiftUI
import SCShared

struct MinutesPicker: View {
    let selectedMinutes: Binding<Int>

    var body: some View {
        Picker("分", selection: selectedMinutes) {
            ForEach(1 ... 59, id: \.self) { minute in
                Text("\(minute)")
                    .tag(minute)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 100)
        .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.minutesPickerView.rawValue)
        .padding(.horizontal, 10)
    }
}
