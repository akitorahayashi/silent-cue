import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

extension TimerReducerTests {
    // テスト: タイマーモード選択時の状態変化と秒数再計算
    func testTimerModeSelection() async {
        let fixedInitialDate = Date(timeIntervalSince1970: 1000) // Use fixed date
        let fixedActionDate = Date(timeIntervalSince1970: 2000) // Use fixed date
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Create initial state with fixed date and calendar
        let initialState = createInitialState(
            now: fixedInitialDate,
            calendar: fixedCalendar // Pass fixed calendar
        )

        // Calculate initial seconds using fixed date and calendar
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedInitialDate,
            calendar: fixedCalendar // Use fixed calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedActionDate) // Use fixed action date
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
            $0.continuousClock = TestClock() // Needed for timer effects, even if not advanced
            $0.calendar = fixedCalendar
        }

        // 初期状態のアサーション
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        // .time を選択
        // Calculate expected hour/minute based on fixed action date and UTC calendar
        let expectedHour = fixedCalendar.component(.hour, from: fixedActionDate)
        let expectedMinute = fixedCalendar.component(.minute, from: fixedActionDate)
        // Calculate expected seconds using fixed date and calendar
        let expectedAtTimeSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: expectedHour,
            selectedMinute: expectedMinute,
            now: fixedActionDate,
            calendar: fixedCalendar // Use fixed calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.time)) { /* 状態変更 */
            $0.timerMode = .time
            $0.selectedHour = expectedHour
            $0.selectedMinute = expectedMinute
            // totalSeconds/currentRemainingSeconds/duration は Reducer が TimeCalculation を呼び出して計算
            $0.totalSeconds = expectedAtTimeSeconds
            $0.currentRemainingSeconds = expectedAtTimeSeconds
            $0.timerDurationMinutes = max(1, (expectedAtTimeSeconds + 59) / 60)
        }

        // 再度 .minutes を選択
        // Calculate expected seconds using fixed date and calendar
        let currentState = store.state
        let expectedAfterMinutesSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: currentState.selectedMinutes,
            selectedHour: currentState.selectedHour,
            selectedMinute: currentState.selectedMinute,
            now: fixedActionDate,
            calendar: fixedCalendar // Use fixed calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.minutes)) { /* 状態変更 */
            $0.timerMode = .minutes
            $0.totalSeconds = expectedAfterMinutesSeconds
            $0.currentRemainingSeconds = expectedAfterMinutesSeconds
            $0.timerDurationMinutes = max(1, (expectedAfterMinutesSeconds + 59) / 60)
            XCTAssertEqual(expectedAfterMinutesSeconds, 60)
        }
        // モード選択アクションはエフェクトを返さないはずだが、念のため完了を確認
        await store.finish()
    }

    // テスト: 分数選択時の状態変化と秒数再計算
    func testMinutesSelected() async {
        let fixedInitialDate = Date(timeIntervalSince1970: 0) // Use fixed date
        let fixedActionDate = Date(timeIntervalSince1970: 100) // Use fixed date
        let initialMinutes = 1
        let newMinutes = 5
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Create initial state with fixed date and calendar
        let initialState = createInitialState(
            now: fixedInitialDate,
            selectedMinutes: initialMinutes,
            timerMode: .minutes,
            calendar: fixedCalendar // Pass fixed calendar
        )
        // Calculate initial seconds using fixed date and calendar
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: initialMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedInitialDate,
            calendar: fixedCalendar // Use fixed calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedActionDate) // Use fixed action date
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
            $0.continuousClock = TestClock()
            $0.calendar = fixedCalendar
        }

        // 初期状態確認
        XCTAssertEqual(store.state.selectedMinutes, initialMinutes)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        // 新しい分数を選択
        // Calculate new seconds using fixed date and calendar
        let expectedNewSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: newMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedActionDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        XCTAssertEqual(expectedNewSeconds, 300)

        await store.send(.minutesSelected(newMinutes)) { state in
            state.selectedMinutes = newMinutes
            // Recalculate seconds using fixed date and calendar
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .minutes,
                selectedMinutes: newMinutes,
                selectedHour: state.selectedHour,
                selectedMinute: state.selectedMinute,
                now: fixedActionDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
            XCTAssertEqual(recalculatedSeconds, expectedNewSeconds)
        }
        await store.finish()
    }

    // テスト: 時刻選択時の状態変化と秒数再計算 (.time モード)
    func testHourMinuteSelected() async {
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Define fixed initial date using UTC
        var components = DateComponents(year: 2023, month: 10, day: 27, hour: 9, minute: 0, second: 0)
        guard let fixedInitialDate = fixedCalendar.date(from: components) else {
            XCTFail("Failed to create fixed initial date using UTC calendar")
            return
        } // 2023-10-27 09:00:00 UTC

        let fixedActionDate = fixedInitialDate.addingTimeInterval(100) // Use fixed date for action

        let initialHour = 9
        let initialMinute = 0
        let newHour = 10
        let newMinute = 30

        // Create initial state using fixed date and calendar
        let initialState = createInitialState(
            now: fixedInitialDate,
            timerMode: .time,
            selectedHour: initialHour,
            selectedMinute: initialMinute,
            calendar: fixedCalendar // Pass fixed calendar
        )
        // Calculate initial seconds using fixed date and calendar
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialHour,
            selectedMinute: initialMinute,
            now: fixedInitialDate,
            calendar: fixedCalendar // Use fixed calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedActionDate) // Use fixed action date
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
            $0.continuousClock = TestClock()
            $0.calendar = fixedCalendar
        }

        // 初期状態確認
        XCTAssertEqual(store.state.timerMode, .time)
        XCTAssertEqual(store.state.selectedHour, initialHour)
        XCTAssertEqual(store.state.selectedMinute, initialMinute)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)

        // 新しい時を選択
        // Calculate expected seconds using fixed date and calendar
        let expectedSecondsAfterHour = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: newHour,
            selectedMinute: initialMinute, // Minute hasn't changed yet
            now: fixedActionDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        await store.send(.hourSelected(newHour)) { state in
            state.selectedHour = newHour
            // Recalculate seconds using fixed date and calendar
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes,
                selectedHour: newHour,
                selectedMinute: initialMinute, // Minute hasn't changed yet
                now: fixedActionDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
            XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterHour)
        }

        // 新しい分を選択
        // Calculate expected seconds using fixed date and calendar
        let expectedSecondsAfterMinute = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: newHour, // Hour has changed
            selectedMinute: newMinute,
            now: fixedActionDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        await store.send(.minuteSelected(newMinute)) { state in
            state.selectedMinute = newMinute
            // Recalculate seconds using fixed date and calendar
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes,
                selectedHour: newHour,
                selectedMinute: newMinute,
                now: fixedActionDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
            XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterMinute)
        }
        await store.finish()
    }
}
