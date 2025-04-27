import ComposableArchitecture // Import TCA for @Dependency
import SwiftUI

/// ナビゲーションの宛先を示す型
enum NavigationDestination: Hashable {
    case countdown
    case completion
    case settings
    case timerStart
}

struct CoordinatorState: Equatable {
    var path: [NavigationDestination]
    var timer: TimerState
    var settings: SettingsState = .init()
    var haptics: HapticsState = .init()

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
    var currentDestination: NavigationDestination? {
        path.last
    }
}
