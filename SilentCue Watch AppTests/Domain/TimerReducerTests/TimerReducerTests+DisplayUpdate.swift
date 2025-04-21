import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

extension TimerReducerTests {
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
        await store
            .receive(.internal(.finalizeTimerCompletion(completionDate: finishDate.addingTimeInterval(1)))) {
                // date依存性の値が使われる
                $0.isRunning = false
                $0.completionDate = finishDate.addingTimeInterval(1)
            }
        await store.finish()
    }
}
