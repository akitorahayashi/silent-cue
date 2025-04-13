@testable import SilentCue_Watch_App
import XCTest

class TimerStateTests: XCTestCase {
    func testInitialState() {
        let state = TimerState()

        // 初期値の確認
        XCTAssertEqual(state.timerMode, .afterMinutes)
        XCTAssertEqual(state.selectedMinutes, 1)
        XCTAssertEqual(state.totalSeconds, 0)
        XCTAssertFalse(state.isRunning)
        XCTAssertEqual(state.displayTime, "00:00")
        XCTAssertNil(state.startDate)
        XCTAssertNil(state.targetEndDate)
        XCTAssertNil(state.completionDate)
        XCTAssertEqual(state.timerDurationMinutes, 0)
        XCTAssertTrue(state.stopVibrationAutomatically)
        XCTAssertEqual(state.selectedHapticType, .standard)
    }

    func testRemainingSecondsCalculation() {
        var state = TimerState()

        // タイマーが実行中でない場合
        state.totalSeconds = 120
        state.isRunning = false
        XCTAssertEqual(state.remainingSeconds, 120)

        // タイマー実行中の場合
        state.isRunning = true
        let now = Date()
        state.startDate = now
        state.targetEndDate = now.addingTimeInterval(90) // 90秒後

        // 実際の経過時間は環境によって変わるため、厳密な値でなく範囲でテスト
        XCTAssertTrue(state.remainingSeconds <= 90 && state.remainingSeconds > 80)

        // ターゲット時刻が過去の場合は0を返す
        state.targetEndDate = now.addingTimeInterval(-10) // 10秒前
        XCTAssertEqual(state.remainingSeconds, 0)
    }

    func testCalculatedTotalSecondsForMinutes() {
        var state = TimerState()

        // 分後モード
        state.timerMode = .afterMinutes
        state.selectedMinutes = 5
        XCTAssertEqual(state.calculatedTotalSeconds, 300) // 5分 = 300秒

        state.selectedMinutes = 10
        XCTAssertEqual(state.calculatedTotalSeconds, 600) // 10分 = 600秒
    }

    func testCalculatedTotalSecondsForTime() {
        var state = TimerState()
        state.timerMode = .atTime

        // 現在時刻より後の時刻を設定
        let calendar = Calendar.current
        let now = Date()
        guard let components = calendar.dateComponents([.hour, .minute], from: now),
              let currentHour = components.hour,
              let currentMinute = components.minute
        else {
            XCTFail("Failed to get date components")
            return
        }

        // 同じ時間の30分後（現在時刻が30分未満の場合）
        if currentMinute < 30 {
            state.selectedHour = currentHour
            state.selectedMinute = 30
            let expectedSeconds = (30 - currentMinute) * 60
            // 誤差を許容するため前後1分の範囲でテスト
            XCTAssertTrue(
                state.calculatedTotalSeconds >= expectedSeconds - 60 &&
                    state.calculatedTotalSeconds <= expectedSeconds + 60
            )
        }

        // 1時間後
        state.selectedHour = (currentHour + 1) % 24
        state.selectedMinute = currentMinute
        let expectedSeconds = 60 * 60 // 1時間 = 3600秒
        // 誤差を許容するため前後1分の範囲でテスト
        XCTAssertTrue(
            state.calculatedTotalSeconds >= expectedSeconds - 60 &&
                state.calculatedTotalSeconds <= expectedSeconds + 60
        )
    }

    func testCalculatedTotalSecondsForPastTime() {
        var state = TimerState()
        state.timerMode = .atTime

        // 現在時刻より前の時刻を設定（次の日とみなされるはず）
        let calendar = Calendar.current
        let now = Date()
        guard let components = calendar.dateComponents([.hour, .minute], from: now),
              let currentHour = components.hour,
              let currentMinute = components.minute
        else {
            XCTFail("Failed to get date components")
            return
        }

        // 現在より1時間前
        let pastHour = (currentHour - 1 + 24) % 24
        state.selectedHour = pastHour
        state.selectedMinute = currentMinute

        // 23時間後になるはず（現在より1時間前 = 翌日の同時刻まで23時間）
        let expectedSeconds = 23 * 60 * 60
        // 誤差を許容するため前後10分の範囲でテスト
        XCTAssertTrue(
            state.calculatedTotalSeconds >= expectedSeconds - 600 &&
                state.calculatedTotalSeconds <= expectedSeconds + 600
        )
    }
}
