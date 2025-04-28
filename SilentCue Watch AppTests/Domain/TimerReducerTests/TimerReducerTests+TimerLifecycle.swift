import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

extension TimerReducerTests {
    // フォアグラウンドでのタイマー完了
    func testTimerFinishes_Foreground() async {
        let fixedNow = Date(timeIntervalSince1970: 0) // Use fixed date
        let selectedMinutes = 1
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        let initialState = createInitialState(
            now: fixedNow,
            selectedMinutes: selectedMinutes,
            calendar: fixedCalendar
        )
        // Calculate initial seconds using fixed calendar
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedNow,
            calendar: fixedCalendar // Use fixed calendar
        )

        let clock = TestClock()
        // TestSupport からモックをインスタンス化
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()
        let finishDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedNow) // Use fixed date
            $0.continuousClock = clock
            // モックインスタンスを注入
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
            $0.calendar = fixedCalendar
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { /* 状態変更 */
            $0.isRunning = true
            $0.startDate = fixedNow // Use fixed date
            $0.targetEndDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // 2. クロックを終了直前まで進める
        await clock.advance(by: .seconds(expectedInitialSeconds - 1))
        // すべてのティックを受信
        for i in 1 ... (expectedInitialSeconds - 1) {
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 1)

        // 3. クロックを終了時刻まで進める
        store.dependencies.date = DateGenerator.constant(finishDate) // finalize 時の Date を設定
        await clock.advance(by: .seconds(1))
        // 最後のティックと完了シーケンスを受信
        await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = 0 }
        await store.receive(TimerReducer.Action.timerFinished)
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }
        // エフェクトの完了を確認
        await store.finish()
    }

    // テスト: タイマー開始、ティック、キャンセルの一連の流れ
    func testStartTickAndCancelTimer() async {
        let fixedNow = Date(timeIntervalSince1970: 0) // Use fixed date
        let selectedMinutes = 2
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        let initialState = createInitialState(
            now: fixedNow,
            selectedMinutes: selectedMinutes,
            calendar: fixedCalendar
        )
        // Calculate initial seconds using fixed calendar
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedNow,
            calendar: fixedCalendar // Use fixed calendar
        )

        let clock = TestClock()
        // TestSupport からモックをインスタンス化
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedNow) // Use fixed date
            $0.continuousClock = clock
            // モックインスタンスを注入
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
            $0.calendar = fixedCalendar
        }

        // 初期状態の確認
        XCTAssertFalse(store.state.isRunning)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 120)

        // タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { /* 状態変更 */
            $0.isRunning = true
            $0.startDate = fixedNow // Use fixed date
            $0.targetEndDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // クロックを1秒進める
        await clock.advance(by: .seconds(1))
        await store.receive(TimerReducer.Action.tick) { /* 状態変更 */
            $0.currentRemainingSeconds = expectedInitialSeconds - 1
        }

        // クロックをさらに9秒進める
        await clock.advance(by: .seconds(9))
        for i in 1 ... 9 {
            await store
                .receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - 1 - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds - 10)

        // タイマーをキャンセル
        let cancelDate = fixedNow.addingTimeInterval(10) // Use fixed date
        store.dependencies.date = DateGenerator.constant(cancelDate)
        // Calculate cancel seconds using fixed calendar
        let expectedCancelSeconds = TimeCalculation.calculateTotalSeconds(
            mode: store.state.timerMode,
            selectedMinutes: store.state.selectedMinutes,
            selectedHour: store.state.selectedHour,
            selectedMinute: store.state.selectedMinute,
            now: cancelDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        XCTAssertEqual(expectedCancelSeconds, 120)

        await store.send(TimerReducer.Action.cancelTimer) { /* 状態変更 */
            $0.isRunning = false
            $0.startDate = nil
            $0.targetEndDate = nil
            $0.completionDate = nil // 完了日もリセット

            // totalSeconds/currentRemainingSeconds は cancelDate 時点での秒数にリセットされる
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: store.state.timerMode,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: $0.selectedHour,
                selectedMinute: $0.selectedMinute,
                now: cancelDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            XCTAssertEqual(recalculatedSeconds, 120) // 120秒のはず
            $0.totalSeconds = recalculatedSeconds
            $0.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60) // Correct expectation
            $0.currentRemainingSeconds = recalculatedSeconds // リセットされる
        }

        // エフェクトがキャンセルされることを確認
        await store.finish()
    }

    func testTimerFinishes_AtTime_Foreground() async throws {
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Define fixed start date using UTC
        var components = DateComponents(year: 2023, month: 10, day: 26, hour: 10, minute: 0, second: 0)
        guard let fixedStartDate = fixedCalendar.date(from: components) else {
            XCTFail("Failed to create fixed start date using UTC calendar")
            return
        } // 2023-10-26 10:00:00 UTC

        // Define target time components
        let targetHour = 10
        let targetMinute = 1

        // Calculate expected target end date using the fixed calendar
        let expectedTargetEndDate = calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        guard let finishDate = expectedTargetEndDate else { // This is the expected finish date/time
            XCTFail("Failed to calculate expected target end date")
            return
        }

        // Create initial state using fixed date and calendar
        let initialState = createInitialState(
            now: fixedStartDate,
            timerMode: .time,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            calendar: fixedCalendar // Use fixed calendar
        )
        // Calculate initial seconds using fixed calendar
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        // Expectation based on fixed start date and target time in UTC
        XCTAssertEqual(expectedInitialSeconds, 60) // 10:00:00 UTC -> 10:01:00 UTC is 60 seconds

        let clock = TestClock()
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedStartDate) // Use fixed start date
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
            $0.calendar = fixedCalendar
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { state in
            state.isRunning = true
            state.startDate = fixedStartDate // Use fixed date
            // Reducer should calculate targetEndDate internally using its calendar
            state.targetEndDate = finishDate // Expect the pre-calculated finish date

            // Recalculate seconds on start using fixed calendar
            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes, // Pass required arg
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            XCTAssertEqual(secondsOnStart, expectedInitialSeconds)
            state.totalSeconds = secondsOnStart
            state.currentRemainingSeconds = secondsOnStart
            state.timerDurationMinutes = max(1, (secondsOnStart + 59) / 60) // Correct expectation
        }

        // 2. クロックを終了直前まで進める
        await clock.advance(by: .seconds(expectedInitialSeconds - 1))
        // すべてのティックを受信
        for i in 1 ... (expectedInitialSeconds - 1) {
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 1)

        // 3. クロックを終了時刻まで進める
        store.dependencies.date = DateGenerator.constant(finishDate) // finalize 時の Date を設定 (10:01:00)
        await clock.advance(by: .seconds(1)) // 最後の1秒を進める
        await Task.yield() // クロックを進めた後の処理を待機

        // 最後のティックと完了シーケンスを受信
        await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = 0 }
        await store.receive(TimerReducer.Action.timerFinished)
        await Task.yield() // timerFinished 後の内部処理を待機

        // finalizeTimerCompletion アクションを受信し、最終状態をアサート
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            // completionDate は finishDate (翌日の目標時刻) であることを期待
            $0.completionDate = finishDate
            // isRunning = false に伴い、関連する状態もリセットされるか確認 (もし必要なら)
            // $0.startDate = nil
            // $0.targetEndDate = nil
            // $0.currentRemainingSeconds = $0.totalSeconds // or expected value after reset
        }
        await Task.yield() // finalizeTimerCompletion 後の処理を待機

        // Effects should be finished by now
        await store.finish()
    }

    // Test: Cross-day .time timer
    func testTimerFinishes_AtTime_CrossDay() async throws {
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Define fixed start date using UTC
        let startComponents = DateComponents(year: 2023, month: 10, day: 26, hour: 23, minute: 59, second: 30)
        guard let fixedStartDate = fixedCalendar.date(from: startComponents) else {
            XCTFail("Failed to create fixed start date using UTC calendar")
            return
        } // 2023-10-26 23:59:30 UTC

        let targetHour = 0
        let targetMinute = 1 // Target: 00:01:00 UTC (next day)

        // Calculate expected finish date using the fixed calendar
        let calculatedTargetEndDate = calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar // Use fixed calendar
        )

        let finishDate = try XCTUnwrap(calculatedTargetEndDate, "Calculated target end date should not be nil")
        // Expected finish date: 2023-10-27 00:01:00 UTC

        // Create initial state using fixed date and calendar
        let initialState = createInitialState(
            now: fixedStartDate,
            timerMode: .time,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            calendar: fixedCalendar // Use fixed calendar
        )
        // Calculate initial seconds using fixed calendar (23:59:30 UTC -> 00:01:00 UTC)
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        XCTAssertEqual(expectedInitialSeconds, 90) // 30s + 60s

        let clock = TestClock()
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedStartDate) // Use fixed date
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
            $0.calendar = fixedCalendar
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { state in
            state.isRunning = true
            state.startDate = fixedStartDate // Use fixed date
            state.targetEndDate = finishDate // Expect the pre-calculated finish date

            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes,
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            state.totalSeconds = secondsOnStart
            state.timerDurationMinutes = max(1, (secondsOnStart + 59) / 60) // Correct expectation
            state.currentRemainingSeconds = secondsOnStart
            XCTAssertEqual(secondsOnStart, 90)
        }

        // 2. クロックを終了時刻まで進める
        store.dependencies.date = DateGenerator.constant(finishDate)
        await clock.advance(by: .seconds(expectedInitialSeconds))

        // すべてのティックと完了シーケンスを受信
        for i in 1 ... expectedInitialSeconds {
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 0)
        await store.receive(TimerReducer.Action.timerFinished)
        // Expect completionDate to match the date dependency set before the final tick
        await store
            .receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) { state in
                state.isRunning = false
                state.completionDate = finishDate
            }
        await store.finish()
    }

    // テスト: .time モードでのタイマー開始、ティック、キャンセル
    func testCancelTimer_AtTime() async throws {
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Define fixed start date using UTC
        let components = DateComponents(year: 2023, month: 10, day: 27, hour: 11, minute: 0, second: 0)
        guard let fixedStartDate = fixedCalendar.date(from: components) else {
            XCTFail("Failed to create fixed start date using UTC calendar")
            return
        } // 2023-10-27 11:00:00 UTC

        let targetHour = 11
        let targetMinute = 2 // Target: 11:02:00 UTC (120 seconds duration)

        // Create initial state using fixed date and calendar
        let initialState = createInitialState(
            now: fixedStartDate,
            timerMode: .time,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            calendar: fixedCalendar // Use fixed calendar
        )

        // Calculate initial seconds using fixed calendar
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        XCTAssertEqual(expectedInitialSeconds, 120)

        // Calculate expected finish date using fixed calendar
        guard let finishDate = calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar // Use fixed calendar
        ) else {
            XCTFail("Failed to calculate expected finish date")
            return
        }

        let clock = TestClock()
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedStartDate) // Use fixed date
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
            $0.calendar = fixedCalendar
        }

        // 1. タイマーを開始
        await store.send(.startTimer) {
            $0.isRunning = true
            $0.startDate = fixedStartDate // Use fixed date
            // Check target end date calculated by helper
            let calculatedTargetEndDate = self.calculateExpectedTargetEndDateAtTime(
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            let unwrappedTargetEndDate = try XCTUnwrap(
                calculatedTargetEndDate,
                "Target end date should not be nil on start"
            )
            XCTAssertEqual(unwrappedTargetEndDate, finishDate)
            $0.targetEndDate = calculatedTargetEndDate

            // Recalculate seconds on start
            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            XCTAssertEqual(secondsOnStart, 120)
            $0.totalSeconds = secondsOnStart
            $0.timerDurationMinutes = max(1, (secondsOnStart + 59) / 60) // Correct expectation
            $0.currentRemainingSeconds = secondsOnStart
        }

        // 2. クロックを10秒進める
        await clock.advance(by: .seconds(10))
        for i in 1 ... 10 {
            await store.receive(.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 110)

        // 3. タイマーをキャンセル
        let cancelDate = fixedStartDate.addingTimeInterval(10) // 11:00:10 UTC
        store.dependencies.date = DateGenerator.constant(cancelDate)

        // Calculate expected seconds on cancel using fixed calendar
        let expectedSecondsOnCancel = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: store.state.selectedMinutes,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: cancelDate,
            calendar: fixedCalendar // Use fixed calendar
        )
        // 11:00:10 UTC to 11:02:00 UTC is 110 seconds
        XCTAssertEqual(expectedSecondsOnCancel, 110)

        await store.send(.cancelTimer) {
            $0.isRunning = false
            $0.startDate = nil
            $0.targetEndDate = nil
            $0.completionDate = nil // 完了日もリセット

            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: $0.selectedHour,
                selectedMinute: $0.selectedMinute,
                now: cancelDate,
                calendar: fixedCalendar // Use fixed calendar
            )
            XCTAssertEqual(recalculatedSeconds, 110)
            $0.totalSeconds = recalculatedSeconds
            $0.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60) // Correct expectation
            $0.currentRemainingSeconds = recalculatedSeconds
        }

        // エフェクトがキャンセルされることを確認
        await store.finish()
    }
}
