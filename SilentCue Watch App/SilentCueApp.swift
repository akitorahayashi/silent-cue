import SwiftUI
import ComposableArchitecture

@main
struct SilentCue_Watch_AppApp: App {
    /// アプリの画面を表す列挙型
    enum AppScreen: Hashable {
        case timerStart
        case countdown
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
            .onAppear {
                // タイマーとSettingsStoreの両方に設定を適用
                timerStore.send(.loadSettings)
                settingsStore.send(.loadSettings)
            }
        }
    }
}
