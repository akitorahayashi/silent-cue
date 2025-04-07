import Foundation
import ComposableArchitecture

/// 設定機能のStoreを提供するクラス
struct SettingsStore {
    /// SettingsReducerのStore
    static func create() -> StoreOf<SettingsReducer> {
        Store(initialState: SettingsState()) {
            SettingsReducer()
        }
    }
} 