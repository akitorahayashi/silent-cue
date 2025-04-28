import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

extension TimerReducerTests {
    // テスト: バックグラウンドでのタイマー完了シーケンス (.minutes モード)
    func testTimerFinishes_Background() async {
        let fixedNow = Date(timeIntervalSince1970: 0) // Use fixed date
        let selectedMinutes = 1 // 60 秒
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Pass fixed calendar to initializer
        let initialState = createInitialState(
            now: fixedNow,
            selectedMinutes: selectedMinutes,
            calendar: fixedCalendar // Pass fixed calendar
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
        // バックグラウンド完了を通知するモックが必要
        let extendedRuntimeService = MockExtendedRuntimeService() // 引数なしで初期化
        let notificationService = MockNotificationService()
        let finishDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedNow) // Use fixed date
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
            $0.calendar = fixedCalendar // Inject the fixed UTC calendar
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) {
            $0.isRunning = true
            $0.startDate = fixedNow // Use fixed date
            $0.targetEndDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // 2. 時間経過をシミュレート (アプリはバックグラウンドなのでティックは受信しない)
        // クロックは概念的に進めるが、.tick アクションは期待しない
        // バックグラウンド完了イベントがトリガーとなる
        // 完了時刻をシミュレートするために date 依存性を進める
        store.dependencies.date = DateGenerator.constant(finishDate)
        // クロックは進めない
        // await clock.advance(by: .seconds(expectedInitialSeconds))

        // 3. バックグラウンド完了イベントをシミュレート
        extendedRuntimeService.triggerCompletion() // モックのヘルパーメソッドを使用
        await store.receive(TimerReducer.Action.internal(.backgroundTimerDidComplete)) // Reducer がバックグラウンドイベントを処理
        // tick タイマーをキャンセルして finalize するはず
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }

        // クロックを進めてタイマーエフェクト（キャンセルされるべきもの）を完了させる
        await clock.advance()

        // エフェクトが終了/キャンセルされたことを確認
        await store.finish()
    }

    // テスト: .time モードでのバックグラウンド完了
    func testTimerFinishes_AtTime_Background() async throws {
        let fixedCalendar = utcCalendar // Use fixed UTC calendar

        // Define fixed start date using UTC
        let startComponents = DateComponents(year: 2023, month: 10, day: 26, hour: 12, minute: 30, second: 0)
        guard let fixedStartDate = fixedCalendar.date(from: startComponents) else {
            XCTFail("Failed to create fixed start date using UTC calendar")
            return
        } // 2023-10-26 12:30:00 UTC

        let targetHour = 12
        let targetMinute = 31 // Target: 12:31:00 UTC (60 seconds duration)

        // Create initial state using fixed date and calendar
        let initialState = createInitialState(
            now: fixedStartDate,
            timerMode: .time,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            calendar: fixedCalendar // Pass fixed calendar
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
        XCTAssertEqual(expectedInitialSeconds, 60)

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
            $0.calendar = fixedCalendar // Inject the fixed UTC calendar
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
            XCTAssertEqual(secondsOnStart, 60)
            $0.totalSeconds = secondsOnStart
            $0.timerDurationMinutes = secondsOnStart / 60
            $0.currentRemainingSeconds = secondsOnStart
        }

        // 2. 時間経過とバックグラウンド完了をシミュレート
        store.dependencies.date = DateGenerator.constant(finishDate) // 完了時刻に date を設定
        // クロックは進めず、ティックも期待しない

        // 3. バックグラウンド完了イベントをトリガー
        extendedRuntimeService.triggerCompletion()
        await store.receive(.internal(.backgroundTimerDidComplete))
        // finalize アクションが送られ、状態が更新される
        await store.receive(.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }

        // クロックを進めてタイマーエフェクト（キャンセルされるべきもの）を完了させる
        await clock.advance()

        // エフェクトが終了/キャンセルされたことを確認
        await store.finish()
    }
}
