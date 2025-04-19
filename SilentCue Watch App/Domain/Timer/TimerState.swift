import Foundation

/// タイマーのモード（分後か時刻指定か）
enum TimerMode: String, Equatable, CaseIterable, Identifiable {
    case afterMinutes = "分数" // 何分後に鳴らすか
    case atTime = "時刻" // 何時に鳴らすか

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
        timerMode: TimerMode = .afterMinutes,
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
        self.selectedHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        self.selectedMinute = currentMinute

        // Call the utility function for calculation
        self.totalSeconds = TimeCalculation.calculateTotalSeconds(
            mode: timerMode,
            selectedMinutes: selectedMinutes,
            selectedHour: self.selectedHour,
            selectedMinute: self.selectedMinute,
            now: now,
            calendar: calendar
        )
        self.currentRemainingSeconds = self.totalSeconds
        self.timerDurationMinutes = self.totalSeconds / 60
    }
}
