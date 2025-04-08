import Foundation
import CasePaths
import ComposableArchitecture

/// タイマーに関連するすべてのアクション
@CasePathable
enum TimerAction: Equatable {
    // タイマーを設定するアクション
    case timerModeSelected(TimerMode)
    case minutesSelected(Int)
    case hourSelected(Int)
    case minuteSelected(Int)
    
    // タイマー操作
    case startTimer
    case cancelTimer
    case pauseTimer
    case resumeTimer
    case tick
    case timerFinished
    
    // バックグラウンド対応
    case updateTimerDisplay
    
    // 設定関連
    case loadSettings
    case settingsLoaded(stopVibration: Bool, hapticType: HapticType)
} 