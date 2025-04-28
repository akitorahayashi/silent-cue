import SCShared
import SwiftUI

struct HourMinutePicker: View {
    let selectedHour: Binding<Int>
    let selectedMinute: Binding<Int>

    var body: some View {
        HStack(spacing: 4) {
            Picker("時", selection: selectedHour) {
                ForEach(0 ..< 24) { hour in
                    Text("\(hour)")
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.hourPicker.rawValue)

            Picker("分", selection: selectedMinute) {
                ForEach(0 ..< 60) { minute in
                    Text(String(format: "%02d", minute))
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.minutePicker.rawValue)
        }
        .frame(height: 100)
        .padding(.horizontal, 6)
    }
}
