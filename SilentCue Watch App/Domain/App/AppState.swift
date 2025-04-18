import SwiftUI

/// アプリ全体のルート状態
struct AppState: Equatable {
    var path: [NavigationDestination]
    var timer: TimerState = .init()
    var settings: SettingsState = .init()
    var haptics: HapticsState = .init()

    init() {
        // 他の State の初期化 ...
        self.timer = TimerState()
        self.settings = SettingsState()
        self.haptics = HapticsState()

        // 起動引数に基づいて path 配列を初期化
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(SCAppEnvironment.LaunchArguments.testingCountdownView.rawValue) {
            self.path = [.countdown]
        } else if arguments.contains(SCAppEnvironment.LaunchArguments.testingSettingsView.rawValue) {
            self.path = [.settings]
        } else if arguments.contains(SCAppEnvironment.LaunchArguments.testingTimerCompletionView.rawValue) {
            self.path = [.completion]
        } else if arguments.contains(SCAppEnvironment.LaunchArguments.testingSetTimerView.rawValue) {
            // SetTimerView の場合は初期パスは空
            self.path = []
        } else {
            // 通常起動時も初期パスは空
            self.path = []
        }
    }

    // ナビゲーションの現在の画面を判断する
    var currentDestination: NavigationDestination? {
        path.last // シンプルな実装に戻す
    }
}
