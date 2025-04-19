import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerReducerLifecycleTests: XCTestCase {
    // --- テストヘルパー ---
    private struct TimerTestSetup {
        let store: TestStore<TimerReducer.State, TimerReducer.Action>
        let clock: TestClock<Duration>
        let startDate: Date
        let expectedInitialSeconds: Int
    }

    private func setupStoreAndStartTimer(
        initialNow: Date,
        selectedMinutes: Int
    ) async -> TimerTestSetup {
        let initialState = TimerReducer.State(testWithNow: initialNow, selectedMinutes: selectedMinutes)
        let expectedSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: initialNow
        )

        let clock = TestClock()
        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(initialNow)
            $0.continuousClock = clock
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // タイマーを開始する
        await store.send(.startTimer) { // 状態変更はここでアサート
            $0.isRunning = true
            $0.startDate = initialNow
            $0.targetEndDate = initialNow.addingTimeInterval(TimeInterval(expectedSeconds))
            $0.totalSeconds = expectedSeconds
            $0.timerDurationMinutes = expectedSeconds / 60
            $0.currentRemainingSeconds = expectedSeconds
        }

        return TimerTestSetup(
            store: store,
            clock: clock,
            startDate: initialNow,
            expectedInitialSeconds: expectedSeconds
        )
    }

    // --- 分割されたテスト ---

    // テスト: タイマー開始時の状態変化が正しいか
    func testStartTimer() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 2

        // ヘルパーを使ってセットアップとタイマー開始
        let setup = await setupStoreAndStartTimer(initialNow: startDate, selectedMinutes: selectedMinutes)

        // ヘルパー内の send ブロックで状態変更はアサート済み
        XCTAssertEqual(setup.expectedInitialSeconds, 120)
        XCTAssertTrue(setup.store.state.isRunning)
        XCTAssertNotNil(setup.store.state.startDate)
        XCTAssertNotNil(setup.store.state.targetEndDate)

        // エフェクト完了待ち
        await setup.store.finish()
    }

    // テスト: タイマーのティックにより残り秒数が正しく減少するか
    func testTimerTicks() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 2

        // セットアップとタイマー開始
        let setup = await setupStoreAndStartTimer(initialNow: startDate, selectedMinutes: selectedMinutes)
        let store = setup.store
        let clock = setup.clock
        let expectedInitialSeconds = setup.expectedInitialSeconds

        // クロックを1秒進める
        await clock.advance(by: .seconds(1))
        await store.receive(.tick) { // 状態変更
            $0.currentRemainingSeconds = expectedInitialSeconds - 1
        }

        // クロックをさらに9秒進める
        await clock.advance(by: .seconds(9))
        for second in 1 ... 9 {
            await store.receive(.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - 1 - second }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds - 10)

        // エフェクト完了待ち
        await store.finish()
    }

    // テスト: タイマーキャンセル時の状態変化とリセットが正しいか
    func testCancelTimer() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 2

        // セットアップとタイマー開始
        let setup = await setupStoreAndStartTimer(initialNow: startDate, selectedMinutes: selectedMinutes)
        let store = setup.store
        let clock = setup.clock
        let expectedInitialSeconds = setup.expectedInitialSeconds

        // ティックをいくつか進める
        await clock.advance(by: .seconds(10))
        await store.skipReceivedActions() // ティックアクションはスキップ
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds - 10)

        // タイマーをキャンセル
        let cancelDate = startDate.addingTimeInterval(10)
        store.dependencies.date = DateGenerator.constant(cancelDate) // キャンセル時の時刻を設定

        // キャンセル時に期待される秒数を再計算（元の合計秒数のはず）
        let expectedCancelSeconds = TimeCalculation.calculateTotalSeconds(
            mode: store.state.timerMode,
            selectedMinutes: store.state.selectedMinutes,
            selectedHour: store.state.selectedHour,
            selectedMinute: store.state.selectedMinute,
            now: cancelDate // キャンセル時刻で計算
        )
        XCTAssertEqual(expectedCancelSeconds, 120)

        await store.send(.cancelTimer) { // 状態変更
            $0.isRunning = false
            $0.startDate = nil
            $0.targetEndDate = nil
            // 再計算され、リセットされる
            $0.totalSeconds = expectedCancelSeconds
            $0.timerDurationMinutes = expectedCancelSeconds / 60
            $0.currentRemainingSeconds = expectedCancelSeconds
        }

        // エフェクト完了待ち
        await store.finish()
    }

    // testTimerFinishes_Foreground はそのままでも良い (50行以下になりそう)
    func testTimerFinishes_Foreground() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1

        let initialState = TimerReducer.State(testWithNow: startDate, selectedMinutes: selectedMinutes)
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )
        XCTAssertEqual(expectedInitialSeconds, 60)

        let clock = TestClock()
        let finishDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // 1. タイマーを開始
        await store.send(.startTimer) {
            $0.isRunning = true
            $0.startDate = startDate
            $0.targetEndDate = finishDate // finishDate を直接使う
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // 2. クロックを終了間際まで進める
        await clock.advance(by: .seconds(expectedInitialSeconds - 1))
        await store.skipReceivedActions()
        XCTAssertEqual(store.state.currentRemainingSeconds, 1)

        // 3. クロックを終了時刻まで進める
        store.dependencies.date = DateGenerator.constant(finishDate)
        await clock.advance(by: .seconds(1))
        await store.receive(.tick) { $0.currentRemainingSeconds = 0 }
        await store.receive(.timerFinished)
        await store.receive(.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }
        await store.finish()
    }
}
