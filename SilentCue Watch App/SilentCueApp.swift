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
    
    // アプリのカラースキームを管理する状態変数
    @State private var colorScheme: ColorScheme = .dark
    
    // UserDefaultsの監視用タイマー
    @State private var settingsMonitorTimer: Timer? = nil
    
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
            .preferredColorScheme(colorScheme)
            .onAppear {
                // UserDefaultsからテーマ設定を読み込む
                updateColorScheme()
                
                // TimerStoreにも同じ設定を適用
                timerStore.send(.loadSettings)
                
                // UserDefaultsの変更を監視するタイマーを設定
                settingsMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    updateColorScheme()
                    timerStore.send(.loadSettings)
                }
            }
            .onDisappear {
                // タイマーを停止
                settingsMonitorTimer?.invalidate()
                settingsMonitorTimer = nil
            }
        }
    }
    
    // テーマ設定を更新する関数
    private func updateColorScheme() {
        let isLightMode = UserDefaultsManager.shared.object(forKey: .appTheme) as? Bool ?? false
        colorScheme = isLightMode ? .light : .dark
    }
}
