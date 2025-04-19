import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerReducerCompletionTests: XCTestCase {
    func testTimerFinishes_Background() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1 // 60秒

        // 新しいイニシャライザを使用
        let initialState = TimerReducer.State(testWithNow: startDate, selectedMinutes: selectedMinutes)
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )

        let clock = TestClock()
        // Mock ExtendedRuntimeService は完了を通知する方法が必要
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

        // 2. 時間経過をシミュレート (ただし、アプリがバックグラウンドにあるため tick は受信されない)
        // クロックを概念的に進めるが、.tick アクションは期待しない
        // バックグラウンド完了イベントがトリガーとなる
        // 完了時刻をシミュレートするために日付依存性を進める
        store.dependencies.date = DateGenerator.constant(finishDate)

        // 3. バックグラウンド完了イベントをシミュレート
        extendedRuntimeService.triggerCompletion() // モックのヘルパーメソッドを使用
        await store.receive(TimerReducer.Action.internal(.backgroundTimerDidComplete)) // リデューサーがバックグラウンドイベントを処理
        // tick タイマーをキャンセルしてファイナライズするはず
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }

        // エフェクトが終了/キャンセルされたことを確認
        await store.finish()
    }

    func testDismissCompletionView() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let completionDate = Date(timeIntervalSince1970: 60)

        // 新しいイニシャライザを使用
        let initialState = TimerReducer.State(
            testWithNow: startDate,
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

        // 潜在的な残存エフェクトがキャンセルされたことを確認 (リデューサーロジックで処理)
        await store.finish()
    }
}
