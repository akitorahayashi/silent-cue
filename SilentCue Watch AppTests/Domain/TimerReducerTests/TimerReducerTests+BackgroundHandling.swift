import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

extension TimerReducerTests {
    // テスト: バックグラウンドでのタイマー完了シーケンス
    func testTimerFinishes_Background() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1 // 60 秒

        let initialState = createInitialState(now: startDate, selectedMinutes: selectedMinutes)
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )

        let clock = TestClock()
        // バックグラウンド完了を通知するモックが必要
        let extendedRuntimeService = MockExtendedRuntimeService() // 引数なしで初期化
        let notificationService = MockNotificationService()
        let finishDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) {
            $0.isRunning = true
            $0.startDate = startDate
            $0.targetEndDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
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

        // エフェクトが終了/キャンセルされたことを確認
        await store.finish()
    }

    // テスト: .time モードでのバックグラウンド完了
    func testTimerFinishes_AtTime_Background() async throws {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var components = DateComponents(
            timeZone: timeZone,
            year: 2023,
            month: 10,
            day: 27,
            hour: 12,
            minute: 30,
            second: 0
        )
        let startDate = calendar.date(from: components)! // 12:30:00 JST

        let targetHour = 12
        let targetMinute = 31 // Target: 12:31:00 JST (60 seconds duration)

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
        XCTAssertEqual(expectedInitialSeconds, 60)

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

        let clock = TestClock() // クロック自体は進めないが、依存性として必要
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

            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: startDate,
                calendar: calendar
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

        // エフェクトが終了/キャンセルされたことを確認
        await store.finish()
    }
}
