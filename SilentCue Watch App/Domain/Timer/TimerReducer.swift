import ComposableArchitecture
import Foundation
import UserNotifications

/// タイマー関連のすべての機能を管理するReducer
struct TimerReducer: Reducer {
    typealias State = TimerState
    // Action は TimerAction.swift で定義
    typealias Action = TimerAction

    // Internal Actions Enum (これはここにネストしても良い、あるいは TimerAction 内でも良い)
    // 外部から直接参照されないため、Reducer 内にある方がカプセル化される場合もある
    enum InternalAction {
        case backgroundTimerDidComplete
        case finalizeTimerCompletion(completionDate: Date)
    }

    // キャンセル用ID
    private enum CancelID { case timer, background }

    // MARK: - 依存関係

    @Dependency(\.continuousClock) var clock
    @Dependency(\.notificationService) var notificationService
    @Dependency(\.extendedRuntimeService) var extendedRuntimeService
    @Dependency(\.date) var date

    // MARK: - Reducer 本体

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // 依存関係はプロパティになったため、Reduceブロックでキャプチャする必要はない

            switch action {
                // タイマー設定のアクション
                case let .timerModeSelected(mode):
                    return handleTimerModeSelected(&state, mode: mode)

                case let .minutesSelected(minutes):
                    return handleMinutesSelected(&state, minutes: minutes)

                case let .hourSelected(hour):
                    return handleHourSelected(&state, hour: hour)

                case let .minuteSelected(minute):
                    return handleMinuteSelected(&state, minute: minute)

                // タイマー操作
                case .startTimer:
                    return handleStartTimer(&state)

                case .cancelTimer:
                    return handleCancelTimer(&state)

                case .tick: // clockエフェクトから受信
                    return handleTick(&state)

                case .timerFinished: // tickがゼロになったときに内部的に送信
                    return handleTimerFinished(&state)

                case .dismissCompletionView:
                    return handleDismissCompletionView(&state)

                // バックグラウンド対応
                case .updateTimerDisplay:
                    return handleUpdateTimerDisplay(&state)

                // --- 内部アクション ---
                case let .internal(internalAction):
                    switch internalAction {
                        case .backgroundTimerDidComplete: // backgroundエフェクトから受信
                            return handleBackgroundTimerDidComplete(&state)
                        case let .finalizeTimerCompletion(completionDate):
                            return handleFinalizeTimerCompletion(&state, completionDate: completionDate)
                    }
            }
        }
    }

    // MARK: - アクション処理メソッド - タイマー設定

    private func handleTimerModeSelected(_ state: inout State, mode: TimerMode) -> Effect<Action> {
        state.timerMode = mode
        if mode == .time {
            let now = date()
            let calendar = Calendar.current
            state.selectedHour = calendar.component(.hour, from: now)
            state.selectedMinute = calendar.component(.minute, from: now)
        }
        recalculateTimerProperties(&state)
        return .none
    }

    private func handleMinutesSelected(_ state: inout State, minutes: Int) -> Effect<Action> {
        state.selectedMinutes = minutes
        recalculateTimerProperties(&state)
        return .none
    }

    private func handleHourSelected(_ state: inout State, hour: Int) -> Effect<Action> {
        state.selectedHour = hour
        recalculateTimerProperties(&state)
        return .none
    }

    private func handleMinuteSelected(_ state: inout State, minute: Int) -> Effect<Action> {
        state.selectedMinute = minute
        recalculateTimerProperties(&state)
        return .none
    }

    // MARK: - アクション処理メソッド - タイマー操作

    // キャンセルIDを使用するマージされたエフェクトに戻す
    private func handleStartTimer(_ state: inout State) -> Effect<Action> {
        guard !state.isRunning else { return .none }
        recalculateTimerProperties(&state)

        let now = date()
        state.startDate = now
        let durationSeconds = state.timerDurationMinutes * 60
        let targetEndDate = now.addingTimeInterval(Double(durationSeconds))
        state.targetEndDate = targetEndDate
        state.isRunning = true
        state.completionDate = nil

        // エフェクトに必要な値をキャプチャ
        let totalSeconds = state.totalSeconds

        // エフェクト1: ティッカー
        let tickerEffect = Effect<Action>.run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.tick)
            }
        }
        .cancellable(id: CancelID.timer)

        // エフェクト2: バックグラウンドセッション / 通知 / 完了監視
        let backgroundEffect = Effect<Action>.run { [targetEndDate, state] send in
            // セッション開始
            extendedRuntimeService.startSession(
                duration: TimeInterval(totalSeconds + 10),
                targetEndTime: targetEndDate
            )
            // 通知をスケジュール
            let content = UNMutableNotificationContent()
            content.title = "タイマー完了"
            content.body = "\\(state.timerDurationMinutes)分のタイマーが完了しました"
            content.sound = .default

            // 日付トリガーの作成
            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: targetEndDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let identifier = "TIMER_COMPLETED_NOTIFICATION" // 識別子を定義

            // プロトコルメソッドを使用して通知を追加
            await Task {
                do {
                    try await notificationService.add(identifier: identifier, content: content, trigger: trigger)
                } catch {
                    // エラーハンドリング (ログ出力など)
                    print("通知スケジュールエラー: \\(error)")
                }
            }.value // Taskを実行
            // 完了イベントを監視
            for await _ in extendedRuntimeService.completionEvents {
                await send(.internal(.backgroundTimerDidComplete))
            }
        }
        .cancellable(id: CancelID.background)

        return .merge(tickerEffect, backgroundEffect)
    }

    // キャンセルIDと直接的なサービス呼び出しを使用するように戻す
    private func handleCancelTimer(_ state: inout State) -> Effect<Action> {
        let wasRunning = state.isRunning
        state.isRunning = false
        state.startDate = nil
        state.targetEndDate = nil
        state.completionDate = nil
        recalculateTimerProperties(&state)

        guard wasRunning else { return .none }

        // 明示的にセッションを停止し、通知をキャンセル
        extendedRuntimeService.stopSession()
        // プロトコルメソッドを使用して通知を削除
        let identifier = "TIMER_COMPLETED_NOTIFICATION" // 識別子を定義
        notificationService.removePendingNotificationRequests(withIdentifiers: [identifier])

        // 実行中のエフェクトをIDでキャンセル
        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.background)
        )
    }

    // --- 状態を直接デクリメントするように変更 ---
    private func handleTick(_ state: inout State) -> Effect<Action> {
        guard state.isRunning else {
            // タイマーが予期せず停止した場合、エフェクトをキャンセル
            return .merge(.cancel(id: CancelID.timer), .cancel(id: CancelID.background))
        }
        // 残り秒数を直接デクリメント
        state.currentRemainingSeconds = max(0, state.currentRemainingSeconds - 1)
        if state.currentRemainingSeconds <= 0 {
            return .send(.timerFinished) // タイマーがゼロになったときに内部アクションを送信
        }
        return .none
    }

    // --- 変更終了 ---

    // フォアグラウンド完了ロジックに戻す
    private func handleTimerFinished(_: inout State) -> Effect<Action> {
        // バックグラウンドエフェクト（セッション/通知/監視）をキャンセル
        // 通知も明示的にキャンセル
        // notificationService.cancelTimerCompletionNotification()
        // プロトコルメソッドを使用して通知を削除
        let identifier = "TIMER_COMPLETED_NOTIFICATION" // 識別子を定義
        notificationService.removePendingNotificationRequests(withIdentifiers: [identifier])
        // 注意: extendedRuntimeService.stopSession() は finalize で呼び出される

        return .concatenate(
            .cancel(id: CancelID.background),
            .send(.internal(.finalizeTimerCompletion(completionDate: date())))
            // タイマーエフェクトは tick が停止するか finalize 経由で自身をキャンセルする
        )
    }

    // MARK: - アクション処理メソッド - バックグラウンド

    private func handleUpdateTimerDisplay(_ state: inout State) -> Effect<Action> {
        if !state.isRunning { return .none }

        if let targetEnd = state.targetEndDate {
            let now = date() // 注入されたdateを使用
            state.currentRemainingSeconds = max(0, Int(ceil(targetEnd.timeIntervalSince(now))))
        } else {
            state.currentRemainingSeconds = 0
        }

        if state.currentRemainingSeconds <= 0 {
            // ここで検出された場合（例：アプリがフォアグラウンドになった時）、完了フローをトリガー
            return .send(.timerFinished)
        }
        return .none
    }

    // MARK: - アクション処理メソッド - Internal

    // バックグラウンド完了ロジックに戻す
    private func handleBackgroundTimerDidComplete(_: inout State) -> Effect<Action> {
        // バックグラウンドエフェクトが完了を通知。
        // tick タイマーエフェクトをキャンセル。
        .concatenate(
            .cancel(id: CancelID.timer),
            .send(.internal(.finalizeTimerCompletion(completionDate: date())))
            // バックグラウンドエフェクトは完了時または finalize 経由で自身をキャンセルする
        )
    }

    // finalize ロジックに戻す
    private func handleFinalizeTimerCompletion(_ state: inout State, completionDate: Date) -> Effect<Action> {
        guard state.isRunning else { return .none }
        state.isRunning = false
        state.completionDate = completionDate

        // 明示的にセッションを停止（既に停止している場合は冪等）
        extendedRuntimeService.stopSession()
        // 残っているエフェクトがあればIDでキャンセル
        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.background)
        )
    }

    // MARK: - アクション処理メソッド - その他

    // dismiss ロジックに戻す
    private func handleDismissCompletionView(_ state: inout State) -> Effect<Action> {
        state.completionDate = nil
        // 残っている可能性のあるエフェクトをキャンセル
        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.background)
        )
    }

    // MARK: - プライベートヘルパーメソッド

    /// Recalculates timer properties (totalSeconds, currentRemainingSeconds, timerDurationMinutes)
    /// based on the current state and injected dependencies.
    /// Should be called whenever timer settings (mode, minutes, hour, minute) change,
    /// or when resetting the timer (e.g., on cancel).
    private func recalculateTimerProperties(_ state: inout State) {
        let now = date()
        state.totalSeconds = TimeCalculation.calculateTotalSeconds(
            mode: state.timerMode,
            selectedMinutes: state.selectedMinutes,
            selectedHour: state.selectedHour,
            selectedMinute: state.selectedMinute,
            now: now
        )
        if !state.isRunning {
            state.currentRemainingSeconds = state.totalSeconds
        }
        state.timerDurationMinutes = state.totalSeconds / 60
    }
}
