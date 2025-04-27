import ComposableArchitecture
import SwiftUI
import SCShared

struct SettingsView: View {
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
            .onAppear {
                if !viewStore.isSettingsLoaded {
                    viewStore.send(.loadSettings)
                }
            }
        })
    }
}
