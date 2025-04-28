import Foundation
import ComposableArchitecture
@testable import SilentCue_Watch_App // Needed for TimerReducer.State and TimerMode

enum TimerReducerTestUtil {
    // テストの一貫性を保つためにUTCに固定されたカレンダーを作成
    static var utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(identifier: "UTC") else {
            fatalError("UTC time zone should always be available.")
        }
        calendar.timeZone = timeZone
        return calendar
    }()

    // .time モードの期待される目標終了日時を計算する
    static func calculateExpectedTargetEndDateAtTime(
        selectedHour: Int,
        selectedMinute: Int,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        dateComponents.hour = selectedHour
        dateComponents.minute = selectedMinute
        dateComponents.second = 0

        guard var targetDate = calendar.date(from: dateComponents) else {
            print("Error: Could not create target date from components in helper.")
            return calendar.date(byAdding: .day, value: 1, to: now)
        }

        if targetDate <= now {
            guard let tomorrowTargetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) else {
                print("Error: Could not calculate tomorrow's target date in helper.")
                return calendar.date(byAdding: .day, value: 1, to: now)
            }
            targetDate = tomorrowTargetDate
        }
        return targetDate
    }

    static func createInitialState(
        now: Date,
        selectedMinutes: Int = 1,
        timerMode: TimerMode = .minutes,
        selectedHour: Int? = nil,
        selectedMinute: Int? = nil,
        isRunning: Bool = false,
        startDate: Date? = nil,
        targetEndDate: Date? = nil,
        completionDate: Date? = nil,
        calendar: Calendar
    ) -> TimerReducer.State {
        var state = TimerReducer.State(
            timerMode: timerMode,
            selectedMinutes: selectedMinutes,
            now: now,
            isRunning: isRunning,
            startDate: startDate,
            targetEndDate: targetEndDate,
            completionDate: completionDate
        )

        var needsRecalculation = false
        if let hour = selectedHour {
            state.selectedHour = hour
            needsRecalculation = true
        }
        if let minute = selectedMinute {
            state.selectedMinute = minute
            needsRecalculation = true
        }

        if needsRecalculation || timerMode == .time {
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: state.timerMode,
                selectedMinutes: state.selectedMinutes,
                selectedHour: state.selectedHour,
                selectedMinute: state.selectedMinute,
                now: now,
                calendar: calendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = recalculatedSeconds / 60
        }

        return state
    }
} 