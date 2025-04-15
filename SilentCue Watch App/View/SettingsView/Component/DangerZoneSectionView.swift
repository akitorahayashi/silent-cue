import SwiftUI

struct DangerZoneSectionView: View {
    @Binding var showResetConfirmationAlert: Bool

    var body: some View {
        Section(
            header: Text("Danger Zone")
                .accessibilityLabel("DangerZoneHeader")
                .accessibilityIdentifier("DangerZoneHeader")
        ) {
            Button("Reset All Settings") {
                showResetConfirmationAlert = true
            }
            .accessibilityLabel("ResetAllSettingsButton")
            .accessibilityIdentifier("ResetAllSettingsButton")
            .foregroundStyle(.red)
        }
    }
}
