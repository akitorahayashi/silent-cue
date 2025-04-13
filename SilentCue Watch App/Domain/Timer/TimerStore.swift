import ComposableArchitecture
import Foundation

/// タイマー機能のStoreを提供するクラス
struct TimerStore {
    /// TimerReducerのStore
    static func create() -> StoreOf<TimerReducer> {
        Store(initialState: TimerState()) {
            TimerReducer()
        }
    }
}
