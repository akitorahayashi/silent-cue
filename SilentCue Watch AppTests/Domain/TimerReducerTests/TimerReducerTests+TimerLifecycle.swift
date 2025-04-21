import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

extension TimerReducerTests {
    // フォアグラウンドでのタイマー完了
    func testTimerFinishes_Foreground() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1

        let initialState = createInitialState(now: startDate, selectedMinutes: selectedMinutes)
        // ユーティリティで初期秒数を計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )

        let clock = TestClock()
        // TestSupport からモックをインスタンス化
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()
        let finishDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            // モックインスタンスを注入
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { /* 状態変更 */
            $0.isRunning = true
            $0.startDate = startDate
            $0.targetEndDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            // 再計算されるが結果は同じはず
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
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 2

        // 初期状態を作成
        let initialState = createInitialState(now: startDate, selectedMinutes: selectedMinutes)
        // 期待される秒数をユーティリティ関数で計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )

        let clock = TestClock()
        // TestSupport からモックをインスタンス化
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            // モックインスタンスを注入
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 初期状態の確認
        XCTAssertFalse(store.state.isRunning)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 120)

        // タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { /* 状態変更 */
            $0.isRunning = true
            $0.startDate = startDate
            $0.targetEndDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            // 再計算されるが結果は同じはず
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
        let cancelDate = startDate.addingTimeInterval(10)
        store.dependencies.date = DateGenerator.constant(cancelDate)
        // キャンセル時の期待される秒数をユーティリティで再計算
        let expectedCancelSeconds = TimeCalculation.calculateTotalSeconds(
            mode: store.state.timerMode, // .minutes のままのはず
            selectedMinutes: store.state.selectedMinutes, // 2 のままのはず
            selectedHour: store.state.selectedHour,
            selectedMinute: store.state.selectedMinute,
            now: cancelDate
        )
        XCTAssertEqual(expectedCancelSeconds, 120) // 120秒のはず

        await store.send(TimerReducer.Action.cancelTimer) { /* 状態変更 */
            $0.isRunning = false
            $0.startDate = nil
            $0.targetEndDate = nil
            // cancelDate を使ってユーティリティで再計算される
            $0.totalSeconds = expectedCancelSeconds
            $0.timerDurationMinutes = expectedCancelSeconds / 60
            $0.currentRemainingSeconds = expectedCancelSeconds // リセット
        }
        // キャンセルによりエフェクトが完了することを期待
        await store.finish()
    }

    func testTimerFinishes_AtTime_Foreground() async throws {
        let calendar = Calendar.current
        guard let timeZone = TimeZone(identifier: "Asia/Tokyo") else {
            XCTFail("Failed to get TimeZone")
            return
        }
        var components = DateComponents(
            timeZone: timeZone,
            year: 2023,
            month: 10,
            day: 26,
            hour: 10,
            minute: 0,
            second: 0
        )
        guard let startDate = calendar.date(from: components) else {
            XCTFail("Failed to create start date")
            return
        } // 10:00:00 JST

        components.hour = 10
        components.minute = 1 // ターゲット時刻: 10:01:00 JST
        guard let targetTime = calendar.date(from: components) else {
            XCTFail("Failed to create target time")
            return
        }

        let initialHour = 10
        let initialMinute = 1

        // 初期状態を作成 (.time)
        let initialState = createInitialState(
            now: startDate,
            timerMode: .time,
            selectedHour: initialHour,
            selectedMinute: initialMinute
        )
        // ユーティリティで初期秒数を計算 (startDate 時点での 10:01:00 までの秒数)
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: initialHour,
            selectedMinute: initialMinute,
            now: startDate,
            calendar: calendar
        )
        XCTAssertEqual(expectedInitialSeconds, 60) // 10:00:00 -> 10:01:00 は 60秒

        let clock = TestClock()
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()
        let finishDate = targetTime // 完了時刻はターゲット時刻

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate) // 開始時の Date
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { state in
            state.isRunning = true
            state.startDate = startDate
            // targetEndDate は now + totalSeconds ではなく、計算された目標時刻になるはず
            // Reducer内部で TimeCalculation.calculateTargetEndDate を使う想定
            // 正確な targetEndDate を計算 (Reducerのロジックに合わせる)
            let calculatedTargetEndDate = try? self.calculateExpectedTargetEndDateAtTime(
                selectedHour: initialHour,
                selectedMinute: initialMinute,
                now: startDate,
                calendar: calendar
            )

            guard let unwrappedTargetEndDate = calculatedTargetEndDate else {
                XCTFail("Calculated target end date should not be nil")
                return
            }
            XCTAssertEqual(unwrappedTargetEndDate, finishDate) // Compare unwrapped value

            state.targetEndDate = calculatedTargetEndDate // Assign the optional value

            // 開始時に totalSeconds/currentRemainingSeconds が再計算される
            // Pass all required args
            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: initialState.selectedMinutes, // Pass required arg
                selectedHour: initialHour,
                selectedMinute: initialMinute,
                now: startDate,
                calendar: calendar
            )
            state.totalSeconds = secondsOnStart
            state.currentRemainingSeconds = secondsOnStart
            state.timerDurationMinutes = secondsOnStart / 60
            XCTAssertEqual(secondsOnStart, expectedInitialSeconds)
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

    // Test: Cross-day .time timer
    func testTimerFinishes_AtTime_CrossDay() async throws {
        let calendar = Calendar.current
        guard let timeZone = TimeZone(identifier: "Asia/Tokyo") else {
            XCTFail("Failed to get TimeZone")
            return
        }
        var startComponents = DateComponents(
            timeZone: timeZone,
            year: 2023,
            month: 10,
            day: 26,
            hour: 23,
            minute: 59,
            second: 30
        )
        guard let startDate = calendar.date(from: startComponents) else {
            XCTFail("Failed to create start date for cross-day test")
            return
        }

        let targetHour = 0
        let targetMinute = 1 // ターゲット時刻: 00:01:00 JST (翌27日)

        // Calculate expected finish date using the helper
        let calculatedTargetEndDate = calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: startDate,
            calendar: calendar
        )

        // Unwrap the result from the helper function for verification
        let unwrappedCalculatedTargetEndDate = try XCTUnwrap(
            calculatedTargetEndDate,
            "Calculated target end date should not be nil"
        )
        // Define the expected finish date for comparison
        let finishDate = startDate.addingTimeInterval(90) // Expected: 2023-10-27 00:01:00 JST
        XCTAssertEqual(
            unwrappedCalculatedTargetEndDate,
            finishDate
        ) // Compare unwrapped helper result with expected date

        // 初期状態を作成 (.time)
        let initialState = createInitialState(
            now: startDate,
            timerMode: .time,
            selectedHour: targetHour, // ターゲットの時
            selectedMinute: targetMinute // ターゲットの分
        )
        // ユーティリティで初期秒数を計算 (23:59:30 -> 翌 00:01:00)
        // Pass all required args
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: startDate,
            calendar: calendar
        )
        XCTAssertEqual(expectedInitialSeconds, 90) // 30秒 + 60秒

        let clock = TestClock()
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { state in
            state.isRunning = true
            state.startDate = startDate
            // Assign the original optional result from the helper to the optional state property
            state.targetEndDate = calculatedTargetEndDate

            // Pass all required args
            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: initialState.selectedMinutes, // Pass required arg
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: startDate,
                calendar: calendar
            )
            state.totalSeconds = secondsOnStart
            state.timerDurationMinutes = secondsOnStart / 60 // Int 除算なので注意
            state.currentRemainingSeconds = secondsOnStart
            XCTAssertEqual(secondsOnStart, 90)
        }

        // 2. クロックを終了時刻まで進める
        // Set the date dependency to the expected finish time for the finalize step
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
        let calendar = Calendar.current
        guard let timeZone = TimeZone(identifier: "Asia/Tokyo") else {
            XCTFail("Failed to get TimeZone")
            return
        }
        var components = DateComponents(
            timeZone: timeZone,
            year: 2023,
            month: 10,
            day: 27,
            hour: 11,
            minute: 0,
            second: 0
        )
        guard let startDate = calendar.date(from: components) else {
            XCTFail("Failed to create start date")
            return
        } // 11:00:00 JST

        let targetHour = 11
        let targetMinute = 2 // Target: 11:02:00 JST (120 seconds duration)

        // 初期状態を作成 (.time)
        let initialState = createInitialState(
            now: startDate,
            timerMode: .time,
            selectedHour: targetHour,
            selectedMinute: targetMinute
        )

        // 期待される初期秒数を計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: startDate,
            calendar: calendar
        )
        XCTAssertEqual(expectedInitialSeconds, 120)

        // 期待される完了時刻を計算
        guard let finishDate = calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: startDate,
            calendar: calendar
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
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 1. タイマーを開始
        await store.send(.startTimer) {
            $0.isRunning = true
            $0.startDate = startDate
            // targetEndDate はヘルパーで計算した値になるはず
            let calculatedTargetEndDate = self.calculateExpectedTargetEndDateAtTime(
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: startDate,
                calendar: calendar
            )
            let unwrappedTargetEndDate = try XCTUnwrap(
                calculatedTargetEndDate,
                "Target end date should not be nil on start"
            )
            XCTAssertEqual(unwrappedTargetEndDate, finishDate)
            $0.targetEndDate = calculatedTargetEndDate

            // 秒数も再計算される
            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: startDate,
                calendar: calendar
            )
            XCTAssertEqual(secondsOnStart, 120)
            $0.totalSeconds = secondsOnStart
            $0.timerDurationMinutes = secondsOnStart / 60
            $0.currentRemainingSeconds = secondsOnStart
        }

        // 2. クロックを10秒進める
        await clock.advance(by: .seconds(10))
        for i in 1 ... 10 {
            await store.receive(.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 110)

        // 3. タイマーをキャンセル
        let cancelDate = startDate.addingTimeInterval(10) // 11:00:10 JST
        store.dependencies.date = DateGenerator.constant(cancelDate)

        // キャンセル時に再計算される期待秒数 (キャンセル時刻時点でのターゲット時刻までの秒数)
        let expectedSecondsOnCancel = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: store.state.selectedMinutes, // Store の現在の値を使用
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: cancelDate, // cancelDate を基準に計算
            calendar: calendar
        )
        // 11:00:10 から 11:02:00 までは 110 秒
        XCTAssertEqual(expectedSecondsOnCancel, 110)

        await store.send(.cancelTimer) {
            $0.isRunning = false
            $0.startDate = nil
            $0.targetEndDate = nil
            $0.completionDate = nil // 完了日もリセット

            // totalSeconds/currentRemainingSeconds は cancelDate 時点での秒数にリセットされる
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: $0.selectedHour, // 維持されているはず
                selectedMinute: $0.selectedMinute, // 維持されているはず
                now: cancelDate, // cancelDate で再計算
                calendar: calendar
            )
            XCTAssertEqual(recalculatedSeconds, 110) // 110秒のはず
            $0.totalSeconds = recalculatedSeconds
            $0.timerDurationMinutes = recalculatedSeconds / 60
            $0.currentRemainingSeconds = recalculatedSeconds // リセットされる
        }

        // エフェクトがキャンセルされることを確認
        await store.finish()
    }
}
