import ComposableArchitecture
import SwiftUI

@main
struct SilentCueWatchApp: App {
    // AppScreen enum は NavigationDestination.swift に移動

    // アプリ全体のストア
    let store = Store(initialState: AppState()) {
        AppReducer()
    }

    // @State private var navPath = NavigationPath() // AppStateで管理

    // バックグラウンド/フォアグラウンド遷移を監視
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // AppStateへの参照を取得 (WindowGroup の内部に移動)
            WithViewStore(store, observe: { $0 }, content: { viewStore in
                // NavigationStackのpathをAppStateとバインド
                NavigationStack(path: viewStore.binding(
                    get: \.path,
                    send: AppAction.pathChanged // Pathの変更をReducerに通知
                )) {
                    // メイン画面としてタイマー設定画面を表示
                    SetTimerView(
                        store: store.scope(
                            state: \.timer,
                            action: AppAction.timer
                        ),
                        onSettingsButtonTapped: {
                            // Viewから遷移アクションを発行
                            viewStore.send(.pushScreen(.settings))
                        },
                        onTimerStart: {
                            // Viewから遷移アクションを発行
                            viewStore.send(.pushScreen(.countdown))
                        }
                    )
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        // 各宛先に対応するViewを構築
                        // case のインデントを修正
                        switch destination {
                            case .countdown:
                                CountdownView(
                                    store: store.scope(
                                        state: \.timer,
                                        action: AppAction.timer
                                    )
                                )
                            case .completion:
                                TimerCompletionView(
                                    store: store.scope(
                                        state: \.timer,
                                        action: AppAction.timer
                                    )
                                )
                            case .settings:
                                SettingsView(
                                    store: store.scope(
                                        state: \.settings,
                                        action: AppAction.settings
                                    ),
                                    hapticsStore: store.scope(
                                        state: \.haptics,
                                        action: AppAction.haptics
                                    )
                                )
                            case .timerStart:
                                EmptyView() // この場合は使われない
                        }
                    }
                }
                .accentColor(.blue)
                .onChange(of: scenePhase) { _, newPhase in
                    // scenePhaseの変更をAppReducerに通知
                    viewStore.send(.scenePhaseChanged(newPhase))
                }
                .onAppear {
                    // アプリ起動時の処理をAppReducerに通知
                    viewStore.send(.onAppear)
                }
            })
        }
    }

    // decodeNavigationPath ヘルパー関数は不要
}
