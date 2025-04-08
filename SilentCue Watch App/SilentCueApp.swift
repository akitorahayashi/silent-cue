import SwiftUI
import ComposableArchitecture

@main
struct SilentCue_Watch_AppApp: App {
    /// アプリの画面を表す列挙型
    enum AppScreen: Hashable {
        case timerStart
        case countdown
        case completion
        case settings
    }
    
    // タイマー機能用のストア
    let timerStore = Store(initialState: TimerState()) {
        TimerReducer()
    }
    
    // 設定機能用のストア
    let settingsStore = Store(initialState: SettingsState()) {
        SettingsReducer()
    }
    
    // 現在の画面を管理する状態変数
    @State private var navPath = NavigationPath()
    @State private var currentScreen: AppScreen = .timerStart
    
    // バックグラウンド/フォアグラウンド遷移を監視
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navPath) {
                // メイン画面としてタイマー設定画面を表示
                TimerStartView(
                    store: timerStore,
                    onSettingsButtonTapped: {
                        currentScreen = .settings
                        navPath.append(AppScreen.settings)
                    },
                    onTimerStart: {
                        currentScreen = .countdown
                        navPath.append(AppScreen.countdown)
                    }
                )
                .navigationDestination(for: AppScreen.self) { screen in
                    switch screen {
                    case .countdown:
                        CountdownView(
                            store: timerStore,
                            onCancel: {
                                navPath.removeLast()
                                currentScreen = .timerStart
                            },
                            onTimerFinished: {
                                // タイマー完了時は現在のパスをクリアして完了画面に移動
                                navPath.removeLast() // カウントダウン画面を削除
                                navPath.append(AppScreen.completion)
                                currentScreen = .completion
                            }
                        )
                    case .completion:
                        TimerCompletionView(
                            store: timerStore,
                            onDismiss: {
                                // 現在のパスをクリアしてTimerStartViewに戻る
                                navPath.removeLast()
                                currentScreen = .timerStart
                            }
                        )
                    case .settings:
                        SettingsView(store: settingsStore)
                    case .timerStart:
                        EmptyView() // この場合は使われない
                    }
                }
            }
            .accentColor(.blue)
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    // フォアグラウンドに戻った場合、タイマーの表示を更新
                    if currentScreen == .countdown {
                        timerStore.send(.updateTimerDisplay)
                    }
                case .background:
                    // バックグラウンドに移行した場合の処理
                    print("App went to background")
                case .inactive:
                    print("App became inactive")
                @unknown default:
                    break
                }
            }
            .onAppear {
                // タイマーとSettingsStoreの両方に設定を適用
                timerStore.send(.loadSettings)
                settingsStore.send(.loadSettings)
            }
        }
    }
}
