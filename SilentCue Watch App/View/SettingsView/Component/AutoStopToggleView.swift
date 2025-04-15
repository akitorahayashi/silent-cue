import SwiftUI

struct AutoStopToggleView: View {
    @Binding var isOn: Bool

    var body: some View {
        Section {
            Toggle("auto-stop after 3s", isOn: $isOn)
                .accessibilityLabel("AutoStopToggle")
                .accessibilityIdentifier("AutoStopToggle")
        }
    }
}
