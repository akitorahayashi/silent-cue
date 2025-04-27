import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerReducerTests: XCTestCase {
    // .time モードの期待される目標終了日時を計算するヘルパー関数
    func calculateExpectedTargetEndDateAtTime(
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
            // 日付が形成できない場合の潜在的なエラーを処理
            print("Error: Could not create target date from components in helper.")
            // 要件に応じて、nil またはデフォルトの未来の日付をオプションで返す
            return calendar.date(byAdding: .day, value: 1, to: now) // 例: 1日後を返す
        }

        // 計算された目標時刻が 'now' に対して過去の場合、
        // 目標は翌日であると仮定する。
        if targetDate <= now {
            guard let tomorrowTargetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) else {
                print("Error: Could not calculate tomorrow's target date in helper.")
                // 要件に応じて、nil またはデフォルトの未来の日付をオプションで返す
                return calendar.date(byAdding: .day, value: 1, to: now) // 例: 1日後を返す
            }
            targetDate = tomorrowTargetDate
        }
        return targetDate
    }

    func createInitialState(
        now: Date,
        selectedMinutes: Int = 1,
        timerMode: TimerMode = .minutes,
        selectedHour: Int? = nil,
        selectedMinute: Int? = nil,
        isRunning: Bool = false,
        startDate: Date? = nil,
        targetEndDate: Date? = nil,
        completionDate: Date? = nil
    ) -> TimerReducer.State {
        // selectedHour/Minute なしでイニシャライザを呼び出す
        var state = TimerReducer.State(
            timerMode: timerMode,
            selectedMinutes: selectedMinutes,
            now: now, // 一貫した初期化のために 'now' を渡す
            isRunning: isRunning,
            startDate: startDate,
            targetEndDate: targetEndDate,
            completionDate: completionDate
        )

        // テスト用に特定の時/分が提供された場合、デフォルトを上書きする
        // そして依存するプロパティを再計算する。
        var needsRecalculation = false
        if let hour = selectedHour {
            state.selectedHour = hour
            needsRecalculation = true
        }
        if let minute = selectedMinute {
            state.selectedMinute = minute
            needsRecalculation = true
        }

        // 時/分が上書きされたか、timerMode が .time の場合にのみ秒を再計算する
        // または timerMode が .minutes で selectedMinutes がデフォルトでない場合 (イニシャライザがこれを処理するが)
        // テスト用に時/分が明示的に提供された場合、再計算する方が安全。
        if needsRecalculation || timerMode == .time {
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: state.timerMode,
                selectedMinutes: state.selectedMinutes,
                selectedHour: state.selectedHour,
                selectedMinute: state.selectedMinute,
                now: now, // createInitialState に渡された 'now' を使用する
                calendar: .current
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds // 新しい合計に基づいて残りの秒数をリセットする
            state.timerDurationMinutes = recalculatedSeconds / 60
        }
        // モードが .minutes で selectedMinutes のみが提供された場合 (時/分ではなく)、
        // イニシャライザは selectedMinutes に基づいて既に正しく計算済み。

        return state
    }
}
