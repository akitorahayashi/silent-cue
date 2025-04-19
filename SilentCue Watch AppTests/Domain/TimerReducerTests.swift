@testable import SilentCue_Watch_App
import ComposableArchitecture
import XCTest

@MainActor
final class TimerReducerTests: XCTestCase {
    // Helper function to calculate expected target end date for .atTime mode
    private func calculateExpectedTargetEndDateAtTime(
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
            // Handle potential error if date cannot be formed
            print("Error: Could not create target date from components in helper.")
            // Optionally return nil or a default future date depending on requirements
            return calendar.date(byAdding: .day, value: 1, to: now) // Example: Return 1 day later
        }

        // If the calculated target time is in the past relative to 'now',
        // assume the target is for the next day.
        if targetDate <= now {
            guard let tomorrowTargetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) else {
                 print("Error: Could not calculate tomorrow's target date in helper.")
                 // Optionally return nil or a default future date
                 return calendar.date(byAdding: .day, value: 1, to: now) // Example: Return 1 day later
            }
            targetDate = tomorrowTargetDate
        }
        return targetDate
    }

    private func createInitialState(
        now: Date,
        selectedMinutes: Int = 1,
        timerMode: TimerMode = .afterMinutes,
        selectedHour: Int? = nil,
        selectedMinute: Int? = nil,
        isRunning: Bool = false,
        startDate: Date? = nil,
        targetEndDate: Date? = nil,
        completionDate: Date? = nil
    ) -> TimerReducer.State {
        // Call the initializer without selectedHour/Minute
        var state = TimerReducer.State(
            timerMode: timerMode,
            selectedMinutes: selectedMinutes,
            now: now, // Pass 'now' for consistent initialization
            isRunning: isRunning,
            startDate: startDate,
            targetEndDate: targetEndDate,
            completionDate: completionDate
        )

        // If specific hour/minute were provided for the test, override the defaults
        // and recalculate dependent properties.
        var needsRecalculation = false
        if let hour = selectedHour {
            state.selectedHour = hour
            needsRecalculation = true
        }
        if let minute = selectedMinute {
            state.selectedMinute = minute
            needsRecalculation = true
        }

        // Recalculate seconds ONLY if hour/minute were overridden or timerMode is .atTime
        // Or if timerMode is .afterMinutes and selectedMinutes is not the default (though initializer handles this)
        // It's safer to recalculate if hour/minute are provided explicitly for the test.
        if needsRecalculation || timerMode == .atTime {
             let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                 mode: state.timerMode,
                 selectedMinutes: state.selectedMinutes,
                 selectedHour: state.selectedHour,
                 selectedMinute: state.selectedMinute,
                 now: now, // Use the 'now' passed to createInitialState
                 calendar: .current
             )
             state.totalSeconds = recalculatedSeconds
             state.currentRemainingSeconds = recalculatedSeconds // Reset remaining seconds based on new total
             state.timerDurationMinutes = recalculatedSeconds / 60
        }
        // If mode is .afterMinutes and only selectedMinutes was provided (not hour/minute),
        // the initializer already calculated correctly based on selectedMinutes.

        return state
    }

    // --- テスト --- //

    // テスト: タイマーモード選択時の状態変化と秒数再計算
    func testTimerModeSelection() async {
        let initialDate = Date(timeIntervalSince1970: 1000)
        let actionDate = Date(timeIntervalSince1970: 2000)
        let calendar = Calendar.current // 一貫性のために Calendar.current を使用

        // 初期状態を作成
        let initialState = createInitialState(now: initialDate)

        // 期待される初期合計秒数をユーティリティ関数で計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: initialDate,
            calendar: calendar // 一貫性のあるカレンダーを渡す
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate)
            // TestSupport からモックを注入
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // 初期状態のアサーション
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        // .atTime を選択
        let expectedHour = calendar.component(.hour, from: actionDate)
        let expectedMinute = calendar.component(.minute, from: actionDate)
        // 期待される合計秒数をユーティリティ関数で計算
        let expectedAtTimeSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
            selectedMinutes: initialState.selectedMinutes, // この値は .atTime では影響しない
            selectedHour: expectedHour,
            selectedMinute: expectedMinute,
            now: actionDate,
            calendar: calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.atTime)) { /* 状態変更 */
            $0.timerMode = .atTime
            $0.selectedHour = expectedHour
            $0.selectedMinute = expectedMinute
            // totalSeconds/currentRemainingSeconds/duration は Reducer が TimeCalculation を呼び出して計算
            $0.totalSeconds = expectedAtTimeSeconds
            $0.currentRemainingSeconds = expectedAtTimeSeconds
            $0.timerDurationMinutes = expectedAtTimeSeconds / 60
        }

        // 再度 .afterMinutes を選択
        // ユーティリティ関数で期待される秒数を計算
        let currentState = store.state // .atTime に切り替えた後の状態を取得
        let expectedAfterMinutesSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .afterMinutes,
            selectedMinutes: currentState.selectedMinutes, // 1 であるはず
            selectedHour: currentState.selectedHour,
            selectedMinute: currentState.selectedMinute,
            now: actionDate,
            calendar: calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.afterMinutes)) { /* 状態変更 */
            $0.timerMode = .afterMinutes
            $0.totalSeconds = expectedAfterMinutesSeconds
            $0.currentRemainingSeconds = expectedAfterMinutesSeconds
            $0.timerDurationMinutes = expectedAfterMinutesSeconds / 60
            XCTAssertEqual(expectedAfterMinutesSeconds, 60)
        }
        // モード選択アクションはエフェクトを返さないはずだが、念のため完了を確認
        await store.finish()
    }

    // テスト: 分数選択時の状態変化と秒数再計算
    func testMinutesSelected() async {
        let initialDate = Date(timeIntervalSince1970: 0)
        let actionDate = Date(timeIntervalSince1970: 100)
        let initialMinutes = 1
        let newMinutes = 5
        let calendar = Calendar.current // Add calendar instance

        // 初期状態を作成 (.afterMinutes)
        let initialState = createInitialState(now: initialDate, selectedMinutes: initialMinutes, timerMode: .afterMinutes)
        // Pass all required args
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .afterMinutes,
            selectedMinutes: initialMinutes,
            selectedHour: initialState.selectedHour, // Pass required arg
            selectedMinute: initialState.selectedMinute, // Pass required arg
            now: initialDate,
            calendar: calendar // Pass calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate)
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
            $0.continuousClock = TestClock() // 依存性として必要
        }

        // 初期状態確認
        XCTAssertEqual(store.state.selectedMinutes, initialMinutes)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        // 新しい分数を選択
        // Pass all required args
        let expectedNewSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .afterMinutes,
            selectedMinutes: newMinutes,
            selectedHour: initialState.selectedHour, // Pass required arg
            selectedMinute: initialState.selectedMinute, // Pass required arg
            now: actionDate,
            calendar: calendar // Pass calendar
        )
        XCTAssertEqual(expectedNewSeconds, 300)

        await store.send(.minutesSelected(newMinutes)) { state in
            state.selectedMinutes = newMinutes
            // Pass all required args for recalculation check
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                 mode: .afterMinutes,
                 selectedMinutes: newMinutes,
                 selectedHour: state.selectedHour,
                 selectedMinute: state.selectedMinute,
                 now: actionDate,
                 calendar: calendar // Pass calendar
             )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = recalculatedSeconds / 60
            XCTAssertEqual(recalculatedSeconds, expectedNewSeconds)
        }
        await store.finish()
    }

    // テスト: 時刻選択時の状態変化と秒数再計算 (.atTime モード)
    func testHourMinuteSelected() async {
        let initialDate = Date(timeIntervalSince1970: 0) // 例: 09:00 JST
        let actionDate = Date(timeIntervalSince1970: 100)
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: TimeZone(identifier: "Asia/Tokyo")!, from: initialDate)
        components.hour = 9
        components.minute = 0
        let initialTime = calendar.date(from: components)!

        let initialHour = 9
        let initialMinute = 0
        let newHour = 10
        let newMinute = 30

        // 初期状態を作成 (.atTime)
        let initialState = createInitialState(now: initialTime, timerMode: .atTime, selectedHour: initialHour, selectedMinute: initialMinute)
        // Pass all required args
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: initialHour,
            selectedMinute: initialMinute,
            now: initialTime,
            calendar: calendar // Pass calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate) // アクション時の時刻
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
            $0.continuousClock = TestClock()
        }

        // 初期状態確認
        XCTAssertEqual(store.state.timerMode, .atTime)
        XCTAssertEqual(store.state.selectedHour, initialHour)
        XCTAssertEqual(store.state.selectedMinute, initialMinute)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)

        // 新しい時を選択
        // Pass all required args
        let expectedSecondsAfterHour = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: newHour,
            selectedMinute: initialMinute,
            now: actionDate,
            calendar: calendar // Pass calendar
        )
        await store.send(.hourSelected(newHour)) { state in
            state.selectedHour = newHour
            // Pass all required args for recalculation check
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                 mode: .atTime,
                 selectedMinutes: state.selectedMinutes, // Pass required arg
                 selectedHour: newHour,
                 selectedMinute: initialMinute,
                 now: actionDate,
                 calendar: calendar // Pass calendar
             )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = recalculatedSeconds / 60
            XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterHour)
        }

        // 新しい分を選択
        // Pass all required args
        let expectedSecondsAfterMinute = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: newHour,
            selectedMinute: newMinute,
            now: actionDate,
            calendar: calendar // Pass calendar
        )
        await store.send(.minuteSelected(newMinute)) { state in
            state.selectedMinute = newMinute
            // Pass all required args for recalculation check
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                 mode: .atTime,
                 selectedMinutes: state.selectedMinutes, // Pass required arg
                 selectedHour: newHour,
                 selectedMinute: newMinute,
                 now: actionDate,
                 calendar: calendar // Pass calendar
             )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = recalculatedSeconds / 60
             XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterMinute)
        }
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
        for i in 1...9 { 
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - 1 - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds - 10)

        // タイマーをキャンセル
        let cancelDate = startDate.addingTimeInterval(10)
        store.dependencies.date = DateGenerator.constant(cancelDate)
        // キャンセル時の期待される秒数をユーティリティで再計算
        let expectedCancelSeconds = TimeCalculation.calculateTotalSeconds(
            mode: store.state.timerMode, // .afterMinutes のままのはず
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

    // テスト: フォアグラウンドでのタイマー完了シーケンス
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
        for i in 1...(expectedInitialSeconds - 1) { 
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

    // テスト: 完了画面の dismiss アクション
    func testDismissCompletionView() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let completionDate = Date(timeIntervalSince1970: 60)

        // タイマーが既に完了した状態で開始
        let initialState = createInitialState(
            now: startDate,
            isRunning: false, // 実行中でない
            completionDate: completionDate // 完了日を持つ
        )

        // このアクションには依存関係は厳密には必要ないが、完全性のために設定
        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(completionDate.addingTimeInterval(1)) // 完了後の時刻
            $0.continuousClock = TestClock()
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // dismiss アクションを送信
        await store.send(TimerReducer.Action.dismissCompletionView) {
            $0.completionDate = nil // completionDate がクリアされることを期待
        }

        // 完了を確認
        await store.finish()
    }

    // テスト: バックグラウンド復帰時の表示更新 (.updateTimerDisplay)
    func testUpdateTimerDisplay_WhenRunning() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 5
        let expectedInitialSeconds = 300

        // タイマー実行中の状態を作成
        let runningState = createInitialState(
            now: startDate,
            selectedMinutes: selectedMinutes,
            isRunning: true,
            startDate: startDate,
            targetEndDate: startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
        )

        let clock = TestClock()
        let store = TestStore(initialState: runningState) {
            TimerReducer()
        } withDependencies: {
            // アクション発生時の時刻を設定 (例: 60秒経過後)
            $0.date = DateGenerator.constant(startDate.addingTimeInterval(60))
            $0.continuousClock = clock
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // 初期残り秒数確認
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds)

        // 表示更新アクションを送信
        await store.send(.updateTimerDisplay) { state in
            // date 依存性の時刻 (startDate + 60s) に基づいて残り秒数が再計算されるはず
            state.currentRemainingSeconds = expectedInitialSeconds - 60
        }
        await store.finish()
    }

    // テスト: タイマー停止中の表示更新は何もしない
    func testUpdateTimerDisplay_WhenNotRunning() async {
        let initialDate = Date(timeIntervalSince1970: 0)
        let initialState = createInitialState(now: initialDate, isRunning: false)

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(initialDate.addingTimeInterval(10))
            $0.continuousClock = TestClock()
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // アクションを送信しても状態は変わらないはず
        await store.send(.updateTimerDisplay)
        await store.finish()
    }

    // テスト: 表示更新時にタイマーが完了するケース
    func testUpdateTimerDisplay_FinishesTimer() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1
        let expectedInitialSeconds = 60
        let finishDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        // タイマー実行中の状態を作成
        let runningState = createInitialState(
            now: startDate,
            selectedMinutes: selectedMinutes,
            isRunning: true,
            startDate: startDate,
            targetEndDate: finishDate
        )

        let clock = TestClock()
        let store = TestStore(initialState: runningState) {
            TimerReducer()
        } withDependencies: {
            // アクション発生時の時刻を完了時刻以降に設定
            $0.date = DateGenerator.constant(finishDate.addingTimeInterval(1))
            $0.continuousClock = clock
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // 表示更新アクションを送信
        await store.send(.updateTimerDisplay) { state in
            // 残り秒数が 0 になるはず
            state.currentRemainingSeconds = 0
        }
        // .updateTimerDisplay が完了を検知し、完了シーケンスが送られることを期待
        await store.receive(.timerFinished)
        await store.receive(.internal(.finalizeTimerCompletion(completionDate: finishDate.addingTimeInterval(1)))) { // date依存性の値が使われる
            $0.isRunning = false
            $0.completionDate = finishDate.addingTimeInterval(1)
        }
        await store.finish()
    }

    // Test: Timer start, tick, complete sequence for .atTime mode (foreground)
    func testTimerFinishes_AtTime_Foreground() async throws {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var components = DateComponents(timeZone: timeZone, year: 2023, month: 10, day: 26, hour: 10, minute: 0, second: 0)
        let startDate = calendar.date(from: components)! // 10:00:00 JST

        components.hour = 10
        components.minute = 1 // ターゲット時刻: 10:01:00 JST
        let targetTime = calendar.date(from: components)!

        let initialHour = 10
        let initialMinute = 1

        // 初期状態を作成 (.atTime)
        let initialState = createInitialState(
            now: startDate,
            timerMode: .atTime,
            selectedHour: initialHour,
            selectedMinute: initialMinute
        )
        // ユーティリティで初期秒数を計算 (startDate 時点での 10:01:00 までの秒数)
        // Pass all required args
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
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
        await store.send(TimerReducer.Action.startTimer) {
            $0.isRunning = true
            $0.startDate = startDate
            // targetEndDate は now + totalSeconds ではなく、計算された目標時刻になるはず
            // Reducer内部で TimeCalculation.calculateTargetEndDate を使う想定
            // 正確な targetEndDate を計算 (Reducerのロジックに合わせる)
            let calculatedTargetEndDate = self.calculateExpectedTargetEndDateAtTime(
                 selectedHour: initialHour,
                 selectedMinute: initialMinute,
                 now: startDate,
                 calendar: calendar
             )

            // Unwrap calculatedTargetEndDate before comparison
            let unwrappedTargetEndDate = try XCTUnwrap(calculatedTargetEndDate, "Calculated target end date should not be nil")
            XCTAssertEqual(unwrappedTargetEndDate, finishDate) // Compare unwrapped value

            $0.targetEndDate = calculatedTargetEndDate // Assign the optional value

            // 開始時に totalSeconds/currentRemainingSeconds が再計算される
            // Pass all required args
            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .atTime,
                selectedMinutes: initialState.selectedMinutes, // Pass required arg
                selectedHour: initialHour,
                selectedMinute: initialMinute,
                now: startDate,
                calendar: calendar
            )
            $0.totalSeconds = secondsOnStart
            $0.timerDurationMinutes = secondsOnStart / 60
            $0.currentRemainingSeconds = secondsOnStart
            XCTAssertEqual(secondsOnStart, 60)
        }

        // 2. クロックを終了直前まで進める
        await clock.advance(by: .seconds(expectedInitialSeconds - 1)) // 59秒進める
        // すべてのティックを受信
        for i in 1...(expectedInitialSeconds - 1) {
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

    // Test: Cross-day .atTime timer
    func testTimerFinishes_AtTime_CrossDay() async throws {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var startComponents = DateComponents(timeZone: timeZone, year: 2023, month: 10, day: 26, hour: 23, minute: 59, second: 30)
        let startDate = calendar.date(from: startComponents)! // 23:59:30 JST (26日)

        let targetHour = 0
        let targetMinute = 1 // ターゲット時刻: 00:01:00 JST (翌27日)

        // Calculate expected finish date using the helper
        let calculatedTargetEndDate = self.calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: startDate,
            calendar: calendar
        )

        // Unwrap the result from the helper function for verification
        let unwrappedCalculatedTargetEndDate = try XCTUnwrap(calculatedTargetEndDate, "Calculated target end date should not be nil")
        // Define the expected finish date for comparison
        let finishDate = startDate.addingTimeInterval(90) // Expected: 2023-10-27 00:01:00 JST
        XCTAssertEqual(unwrappedCalculatedTargetEndDate, finishDate) // Compare unwrapped helper result with expected date

        // 初期状態を作成 (.atTime)
        let initialState = createInitialState(
            now: startDate,
            timerMode: .atTime,
            selectedHour: targetHour, // ターゲットの時
            selectedMinute: targetMinute // ターゲットの分
        )
        // ユーティリティで初期秒数を計算 (23:59:30 -> 翌 00:01:00)
        // Pass all required args
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
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
        await store.send(TimerReducer.Action.startTimer) {
            $0.isRunning = true
            $0.startDate = startDate
            // Assign the original optional result from the helper to the optional state property
            $0.targetEndDate = calculatedTargetEndDate

            // Pass all required args
            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .atTime,
                selectedMinutes: initialState.selectedMinutes, // Pass required arg
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: startDate,
                calendar: calendar
            )
            $0.totalSeconds = secondsOnStart
            $0.timerDurationMinutes = secondsOnStart / 60 // Int 除算なので注意
            $0.currentRemainingSeconds = secondsOnStart
            XCTAssertEqual(secondsOnStart, 90)
        }

        // 2. クロックを終了時刻まで進める
        // Set the date dependency to the expected finish time for the finalize step
        store.dependencies.date = DateGenerator.constant(finishDate)
        await clock.advance(by: .seconds(expectedInitialSeconds))

        // すべてのティックと完了シーケンスを受信
        for i in 1...expectedInitialSeconds {
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 0)
        await store.receive(TimerReducer.Action.timerFinished)
        // Expect completionDate to match the date dependency set before the final tick
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }
        await store.finish()
    }

    // テスト: .atTime モードでのタイマー開始、ティック、キャンセル
    func testCancelTimer_AtTime() async throws {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var components = DateComponents(timeZone: timeZone, year: 2023, month: 10, day: 27, hour: 11, minute: 0, second: 0)
        let startDate = calendar.date(from: components)! // 11:00:00 JST

        let targetHour = 11
        let targetMinute = 2 // Target: 11:02:00 JST (120 seconds duration)

        // 初期状態を作成 (.atTime)
        let initialState = createInitialState(
            now: startDate,
            timerMode: .atTime,
            selectedHour: targetHour,
            selectedMinute: targetMinute
        )

        // 期待される初期秒数を計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
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
             let unwrappedTargetEndDate = try XCTUnwrap(calculatedTargetEndDate, "Target end date should not be nil on start")
             XCTAssertEqual(unwrappedTargetEndDate, finishDate)
            $0.targetEndDate = calculatedTargetEndDate

            // 秒数も再計算される
             let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                 mode: .atTime,
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
        for i in 1...10 {
            await store.receive(.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 110)

        // 3. タイマーをキャンセル
        let cancelDate = startDate.addingTimeInterval(10) // 11:00:10 JST
        store.dependencies.date = DateGenerator.constant(cancelDate)

        // キャンセル時に再計算される期待秒数 (キャンセル時刻時点でのターゲット時刻までの秒数)
        let expectedSecondsOnCancel = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
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
                 mode: .atTime,
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

    // テスト: .atTime モードでのバックグラウンド完了
    func testTimerFinishes_AtTime_Background() async throws {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var components = DateComponents(timeZone: timeZone, year: 2023, month: 10, day: 27, hour: 12, minute: 30, second: 0)
        let startDate = calendar.date(from: components)! // 12:30:00 JST

        let targetHour = 12
        let targetMinute = 31 // Target: 12:31:00 JST (60 seconds duration)

        // 初期状態を作成 (.atTime)
        let initialState = createInitialState(
            now: startDate,
            timerMode: .atTime,
            selectedHour: targetHour,
            selectedMinute: targetMinute
        )

        // 期待される初期秒数を計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
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
            let unwrappedTargetEndDate = try XCTUnwrap(calculatedTargetEndDate, "Target end date should not be nil on start")
            XCTAssertEqual(unwrappedTargetEndDate, finishDate)
            $0.targetEndDate = calculatedTargetEndDate

            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .atTime,
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

