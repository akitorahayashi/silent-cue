import ComposableArchitecture
import SCShared
import SwiftUI

/// ナビゲーションの宛先を示す型
enum NavigationDestination: Hashable {
    case countdown
    case completion
    case settings
    case timerStart
}

/// アプリ全体のナビゲーションと状態を管理する
struct CoordinatorState: Equatable {
    // 各画面の状態
    var timer = TimerState()
    var settings = SettingsState()
    var haptics = HapticsState()

    // ナビゲーションパス
    var path: [NavigationDestination] = []

    // 通知アラート表示状態
    var shouldShowNotificationAlert: Bool = false

    init(
        date: Date = Date() // Can still inject Date if needed
    ) {
        // Initialize TimerState - it no longer needs calendar or calculator
        timer = TimerState(now: date)

        // Initialize path based on launch arguments
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(SCAppEnvironment.InitialViewOption.countdownView.rawValue) {
            path = [.countdown]
        } else if arguments.contains(SCAppEnvironment.InitialViewOption.settingsView.rawValue) {
            path = [.settings]
        } else if arguments.contains(SCAppEnvironment.InitialViewOption.timerCompletionView.rawValue) {
            path = [.completion]
        } else if arguments.contains(SCAppEnvironment.InitialViewOption.setTimerView.rawValue) {
            path = []
        } else {
            // Default launch path
            path = []
        }
    }

    // ナビゲーションの現在の画面を判断する
    // var currentDestination: NavigationDestination? { // Reverted
    //     path.last // Array already has .last
    // }
}
