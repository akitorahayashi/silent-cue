import SwiftUI

struct SelectVibrationTypeSection: View {
    let hapticTypes: [HapticType]
    let selectedHapticType: HapticType
    let onSelect: (HapticType) -> Void

    var body: some View {
        Section(
            header: Text("Vibration Type")
                .accessibilityLabel("VibrationTypeHeader")
                .accessibilityIdentifier("VibrationTypeHeader")
        ) {
            ForEach(hapticTypes) { hapticType in
                Button(action: {
                    onSelect(hapticType)
                }, label: {
                    HStack {
                        Text(hapticType.rawValue.capitalized)
                        Spacer()
                        if hapticType == selectedHapticType {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(Color.green.opacity(0.7))
                                .transition(.opacity)
                                .animation(.spring(), value: selectedHapticType)
                        }
                    }
                })
                .accessibilityLabel("VibrationTypeOption\(hapticType.rawValue.capitalized)")
                .accessibilityIdentifier("VibrationTypeOption\(hapticType.rawValue.capitalized)")
            }
        }
    }
}
