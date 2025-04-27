import ComposableArchitecture
import Foundation

/// タイマーに関連するすべてのアクション
enum TimerAction: Equatable {
    // Internal Actions
    enum InternalAction: Equatable {
        case backgroundTimerDidComplete
        case finalizeTimerCompletion(completionDate: Date)
    }

    // MARK: - Public Actions

    // タイマーを設定するアクション
    case timerModeSelected(TimerMode)
    case minutesSelected(Int)
    case hourSelected(Int)
    case minuteSelected(Int)

    // タイマー操作
    case startTimer
    case cancelTimer
    case tick
    case timerFinished
    case dismissCompletionView

    // バックグラウンド対応
    case updateTimerDisplay

    // MARK: - Internal Actions

    case `internal`(InternalAction)
}
