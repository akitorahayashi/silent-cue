import Foundation
import ComposableArchitecture

/// タイマーのモード（分後か時刻指定か）
enum TimerMode: String, Equatable, CaseIterable, Identifiable {
    case minutes = "分数"
    case time = "時刻"

    var id: String { rawValue }
}

/// タイマーの状態を管理するクラス
struct TimerState: Equatable {
    // タイマー設定の状態
    var timerMode: TimerMode
    var selectedMinutes: Int
    var selectedHour: Int
    var selectedMinute: Int

    // カウントダウンの状態
    var totalSeconds: Int
    var currentRemainingSeconds: Int
    var isRunning: Bool
    var displayTime: String {
        SCTimeFormatter.formatSecondsToTimeString(currentRemainingSeconds)
    }

    // バックグラウンド対応のための時間情報
    var startDate: Date?
    var targetEndDate: Date?

    // 完了画面用の情報
    var completionDate: Date?
    var timerDurationMinutes: Int

    // Reverted initializer: Removed calendar and timerCalculator parameters
    // Uses Date() and Calendar.current implicitly for defaults
    init(
        timerMode: TimerMode = .minutes,
        selectedMinutes: Int = 1,
        now: Date = Date(), // Keep explicit now for testability
        isRunning: Bool = false,
        startDate: Date? = nil,
        targetEndDate: Date? = nil,
        completionDate: Date? = nil
    ) {
        self.timerMode = timerMode
        self.selectedMinutes = selectedMinutes
        self.isRunning = isRunning
        self.startDate = startDate
        self.targetEndDate = targetEndDate
        self.completionDate = completionDate

        let calendar = Calendar.current
        selectedHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        selectedMinute = currentMinute

        // Call the utility function for calculation
        totalSeconds = TimeCalculation.calculateTotalSeconds(
            mode: timerMode,
            selectedMinutes: selectedMinutes,
            selectedHour: selectedHour,
            selectedMinute: selectedMinute,
            now: now,
            calendar: calendar
        )
        currentRemainingSeconds = totalSeconds
        timerDurationMinutes = totalSeconds / 60
    }
}
