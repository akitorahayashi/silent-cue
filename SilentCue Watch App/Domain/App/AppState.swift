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
        if arguments.contains(SCAppEnvironment.InitialViewOption.countdownView.rawValue) {
            self.path = [.countdown]
        } else if arguments.contains(SCAppEnvironment.InitialViewOption.settingsView.rawValue) {
            self.path = [.settings]
        } else if arguments.contains(SCAppEnvironment.InitialViewOption.timerCompletionView.rawValue) {
            self.path = [.completion]
        } else if arguments.contains(SCAppEnvironment.InitialViewOption.setTimerView.rawValue) {
            self.path = []
        } else {
            // 通常起動時
            self.path = []
        }
    }

    // ナビゲーションの現在の画面を判断する
    var currentDestination: NavigationDestination? {
        path.last
    }
}
