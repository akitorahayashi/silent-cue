import CasePaths
import ComposableArchitecture
import SwiftUI

/// アプリ全体のルートReducer
struct AppReducer: Reducer {
    typealias State = AppState
    typealias Action = AppAction

    var body: some ReducerOf<Self> {
        // 各機能ドメインのReducerをScopeで接続
        Scope(state: \.timer, action: /AppAction.timer) {
            TimerReducer()
        }
        Scope(state: \.settings, action: /AppAction.settings) {
            SettingsReducer()
        }
        Scope(state: \.haptics, action: /AppAction.haptics) {
            HapticsReducer()
        }

        // AppReducer自体のロジック (機能間連携、ナビゲーションなど)
        Reduce { state, action in
            // Access dependencies via the implicit `dependencies` parameter
            @Dependency(\.extendedRuntimeService) var extendedRuntimeService

            switch action {
            // MARK: - アプリライフサイクル

                case .onAppear:
                    // アプリ起動時に設定を読み込む
                    return .send(.settings(.loadSettings))

                case let .scenePhaseChanged(newPhase):
                    // バックグラウンドから復帰時の処理
                    if newPhase == .active {
                        var effects: [Effect<Action>] = []

                        // カウントダウン画面表示中ならタイマー表示を更新
                        if state.path.last == .countdown {
                            effects.append(.send(.timer(.updateTimerDisplay)))
                        }

                        // タイマーが完了済みで、かつ完了画面にまだ遷移していない場合、完了画面へ遷移させる
                        guard state.timer.completionDate != nil else {
                            return .merge(effects) // タイマー未完了なら何もしない
                        }
                        guard state.path.last != .completion else {
                            return .merge(effects) // すでに完了画面なら何もしない
                        }

                        // 上記ガードを通過した場合のみ実行
                        print("AppReducer: Detected completed timer on becoming active, navigating to completion.")
                        effects.append(.send(.pushScreen(.completion)))

                        return .merge(effects)
                    }
                    return .none

            // MARK: - ナビゲーション

                case let .pathChanged(newPath):
                    state.path = newPath
                    return .none

                case let .pushScreen(destination):
                    state.path.append(destination)
                    return .none

                case .popScreen:
                    // 戻る前に振動停止などの副作用を実行
                    let effect = state.haptics.isActive ? Effect<AppAction>
                        .send(.haptics(HapticsAction.stopHaptic)) : Effect.none
                    // NavigationStack Bindingが自動でpopするので、state変更は不要な場合が多い
                    // state.path.removeLast() // 必要ならコメント解除
                    return effect

            // MARK: - 機能連携

                case let .settings(.settingsLoaded(hapticType)):
                    // 設定ロード完了時: HapticsReducerに直接設定を伝える
                    return .send(.haptics(.updateHapticSettings(
                        type: hapticType // Actionのペイロードを使う
                    )))

                case .settings(.selectHapticType):
                    // 設定変更時: SettingsReducerで状態が更新された後、HapticsReducerに直接設定を伝える
                    return .send(.haptics(.updateHapticSettings(
                        type: state.settings.selectedHapticType
                    )))

                case .timer(.cancelTimer):
                    // Haptics停止と同時に前の画面へ
                    state.path.removeLast() // 先にパスを更新
                    return .send(.haptics(.stopHaptic))

                case .timer(.dismissCompletionView): // TimerCompletionViewのonDismissから呼ばれる想定
                    // Haptics停止と同時にルート画面に戻る
                    state.path.removeAll()
                    return .send(.haptics(.stopHaptic))

                // タイマーアクションを監視
                case let .timer(timerAction):
                    // 新しい finalizeTimerCompletion を監視して完了処理を実行
                    if case .internal(.finalizeTimerCompletion) = timerAction {
                        // Haptics開始と同時に完了画面へ遷移
                        // (バックグラウンド完了かどうかの判定はTimerReducer内で行われ、
                        //  ここでは共通の完了後処理として実行)
                        return .merge(
                            .send(.haptics(.startHaptic(state.settings.selectedHapticType))),
                            .send(.pushScreen(.completion)) // pathにcompletionを追加
                        )
                    }
                    // 他のタイマーアクションはここでは無視
                    return .none

            // MARK: - ドメインアクション（ここでは何もしない）

                case .settings, .haptics:
                    return .none
            }
        }
    }
}
