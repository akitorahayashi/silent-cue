import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsReducer>
    let hapticsStore: StoreOf<HapticsReducer>

    // アラート表示用の状態変数
    @State private var showResetAlert = false
    @State private var showResetConfirmationAlert = false

    init(store: StoreOf<SettingsReducer>, hapticsStore: StoreOf<HapticsReducer>) {
        self.store = store
        self.hapticsStore = hapticsStore
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            List {
                AutoStopToggleView(isOn: viewStore.binding(
                    get: { $0.stopVibrationAutomatically },
                    send: { SettingsAction.toggleStopVibrationAutomatically($0) }
                ))

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

                DangerZoneSectionView(showResetConfirmationAlert: $showResetConfirmationAlert)
            }
            .navigationTitle("Settings")
            .onAppear {
                if !viewStore.hasLoaded {
                    viewStore.send(.loadSettings)
                }
            }
            .alert("すべての設定項目が初期値に戻されました", isPresented: $showResetAlert) {
                Button("OK") {
                    showResetAlert = false
                }
            }
            .alert("設定をリセットしますか？", isPresented: $showResetConfirmationAlert) {
                Button("キャンセル", role: .cancel) {
                    showResetConfirmationAlert = false
                }
                Button("リセット", role: .destructive) {
                    UserDefaultsManager.shared.removeAll()
                    viewStore.send(.loadSettings)
                    showResetConfirmationAlert = false

                    // 少し遅延させて完了アラートを表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showResetAlert = true
                    }
                }
            } message: {
                Text("この操作は取り消せません")
            }
        })
    }
}
