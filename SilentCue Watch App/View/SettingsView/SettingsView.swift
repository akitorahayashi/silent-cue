import ComposableArchitecture
import SCShared
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    let store: StoreOf<SettingsReducer>
    let hapticsStore: StoreOf<HapticsReducer>

    init(store: StoreOf<SettingsReducer>, hapticsStore: StoreOf<HapticsReducer>) {
        self.store = store
        self.hapticsStore = hapticsStore
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            List {
                SelectVibrationTypeSection(
                    hapticTypes: HapticType.allCases,
                    selectedHapticType: viewStore.selectedHapticType,
                    onSelect: { hapticType in
                        viewStore.send(.selectHapticType(hapticType))
                    }
                )
            }
            .navigationTitle(SCAccessibilityIdentifiers.SettingsView.navigationBarTitle.rawValue)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .aspectRatio(contentMode: .fit)
                    }
                    .accessibilityIdentifier(SCAccessibilityIdentifiers.SettingsView.backButton.rawValue)
                }
            }
            .onAppear {
                if !viewStore.isSettingsLoaded {
                    viewStore.send(.loadSettings)
                }
            }
        })
    }
}
