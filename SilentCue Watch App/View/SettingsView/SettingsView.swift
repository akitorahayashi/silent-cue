import ComposableArchitecture
import SwiftUI

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
                VibrationTypeSectionView(
                    hapticTypes: HapticType.allCases,
                    selectedHapticType: viewStore.selectedHapticType,
                    onSelect: { hapticType in
                        // 設定変更
                        viewStore.send(.selectHapticType(hapticType))

                        // ハプティックスストアでプレビュー
                        hapticsStore.send(.previewHaptic(hapticType))
                    }
                )
            }
            .navigationTitle("Settings")
            .onAppear {
                if !viewStore.isSettingsLoaded {
                    viewStore.send(.loadSettings)
                }
            }
        })
    }
}
