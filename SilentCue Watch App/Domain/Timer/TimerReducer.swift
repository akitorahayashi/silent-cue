import ComposableArchitecture
import Foundation

/// タイマー関連のすべての機能を管理するReducer
struct TimerReducer: Reducer {
    typealias State = TimerState
    typealias Action = TimerAction

    @Dependency(\.continuousClock) var clock

    private enum CancelID { case timer }

    // バックグラウンドコールバック用の静的変数
    private static var backgroundTimerCallback: (() -> Void)?

    // MARK: - Reducer Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
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

                case .tick:
                    return handleTick(&state)

                case .timerFinished:
                    return handleTimerFinished(&state)

                case .backgroundTimerFinished:
                    return handleBackgroundTimerFinished(&state)

                case .dismissCompletionView:
                    return handleDismissCompletionView(&state)

                // バックグラウンド対応
                case .updateTimerDisplay:
                    return handleUpdateTimerDisplay(&state)
            }
        }
    }

    // MARK: - アクション処理メソッド - タイマー設定

    private func handleTimerModeSelected(_ state: inout State, mode: TimerMode) -> Effect<Action> {
        state.timerMode = mode

        // 時刻モードに切り替わった場合、現在時刻を設定
        if mode == .atTime {
            let now = Date()
            let calendar = Calendar.current
            state.selectedHour = calendar.component(.hour, from: now)
            state.selectedMinute = calendar.component(.minute, from: now)
        }

        return .none
    }

    private func handleMinutesSelected(_ state: inout State, minutes: Int) -> Effect<Action> {
        state.selectedMinutes = minutes
        return .none
    }

    private func handleHourSelected(_ state: inout State, hour: Int) -> Effect<Action> {
        state.selectedHour = hour
        return .none
    }

    private func handleMinuteSelected(_ state: inout State, minute: Int) -> Effect<Action> {
        state.selectedMinute = minute
        return .none
    }

    // MARK: - アクション処理メソッド - タイマー操作

    private func handleStartTimer(_ state: inout State) -> Effect<Action> {
        // 開始時間と終了時間を設定
        let now = Date()
        state.totalSeconds = state.calculatedTotalSeconds
        state.startDate = now
        state.targetEndDate = now.addingTimeInterval(TimeInterval(state.totalSeconds))
        state.displayTime = SCTimeFormatter.formatSecondsToTimeString(state.remainingSeconds)
        state.isRunning = true

        // 完了情報をリセット
        state.completionDate = nil
        state.timerDurationMinutes = state.totalSeconds / 60

        // 非同期クロージャーで使う値を先に取得
        let targetEndDate = state.targetEndDate
        let totalSeconds = state.totalSeconds
        let durationMinutes = state.timerDurationMinutes

        // タイマー完了通知をスケジュール
        if let targetDate = targetEndDate {
            NotificationManager.shared.scheduleTimerCompletionNotification(
                at: targetDate,
                minutes: durationMinutes
            )
        }

        // バックグラウンドタイマー用コールバックを保存
        return .run { send in
            // バックグラウンドコールバックを設定
            Self.backgroundTimerCallback = {
                // バックグラウンドでタイマーが完了したら通知
                Task { @MainActor in
                    send(.backgroundTimerFinished)
                }
            }

            // バックグラウンド処理のコールバックを設定
            ExtendedRuntimeManager.shared.startSession(
                duration: TimeInterval(totalSeconds + 10),
                targetEndTime: targetEndDate,
                completionHandler: {
                    // バックグラウンドでタイマーが完了したらコールバックを実行
                    DispatchQueue.main.async {
                        Self.backgroundTimerCallback?()
                    }
                }
            )

            // 1秒ごとに発火するタイマーをセットアップ
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.tick)
            }
        }
        .cancellable(id: CancelID.timer)
    }

    private func handleCancelTimer(_ state: inout State) -> Effect<Action> {
        state.isRunning = false
        state.startDate = nil
        state.targetEndDate = nil
        state.completionDate = nil

        // コールバックをクリア
        Self.backgroundTimerCallback = nil

        // 拡張ランタイムセッションを停止
        ExtendedRuntimeManager.shared.stopSession()
        
        // 通知をキャンセル
        NotificationManager.shared.cancelTimerCompletionNotification()

        return .cancel(id: CancelID.timer)
    }

    private func handleTick(_ state: inout State) -> Effect<Action> {
        // 残り時間を計算（計算プロパティになったので直接更新は不要）
        // 表示だけを更新
        state.displayTime = SCTimeFormatter.formatSecondsToTimeString(state.remainingSeconds)

        // タイマー完了判定
        if state.remainingSeconds <= 0 {
            return .send(.timerFinished)
        }

        return .none
    }

    private func handleTimerFinished(_ state: inout State) -> Effect<Action> {
        state.isRunning = false

        // 完了情報を保存
        state.completionDate = Date()

        // コールバックをクリア
        Self.backgroundTimerCallback = nil

        // 拡張ランタイムセッションを停止
        ExtendedRuntimeManager.shared.stopSession()
        
        // タイマー完了時は通知をキャンセル（すでにアプリ内にいるため）
        NotificationManager.shared.cancelTimerCompletionNotification()

        return .none
    }

    private func handleBackgroundTimerFinished(_ state: inout State) -> Effect<Action> {
        // バックグラウンドでタイマーが完了した時
        if !state.isRunning {
            return .none
        }

        state.isRunning = false
        state.completionDate = Date()

        // コールバックをクリア
        Self.backgroundTimerCallback = nil

        // 拡張ランタイムセッションを停止
        ExtendedRuntimeManager.shared.stopSession()

        return .none
    }

    private func handleDismissCompletionView(_ state: inout State) -> Effect<Action> {
        // 完了情報をリセット
        state.completionDate = nil

        // コールバックをクリア
        Self.backgroundTimerCallback = nil

        return .cancel(id: CancelID.timer)
    }

    // MARK: - アクション処理メソッド - バックグラウンド

    private func handleUpdateTimerDisplay(_ state: inout State) -> Effect<Action> {
        // バックグラウンドから復帰時に表示を更新
        if !state.isRunning {
            return .none
        }

        state.displayTime = SCTimeFormatter.formatSecondsToTimeString(state.remainingSeconds)

        // タイマー完了判定
        if state.remainingSeconds <= 0 {
            return .send(.timerFinished)
        }

        return .none
    }
}
