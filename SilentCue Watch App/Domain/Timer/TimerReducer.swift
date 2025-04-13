import ComposableArchitecture
import Foundation
import WatchKit

/// タイマー関連のすべての機能を管理するReducer
struct TimerReducer: Reducer {
    typealias State = TimerState
    typealias Action = TimerAction

    @Dependency(\.continuousClock) var clock
    @Dependency(\.userDefaultsManager) var userDefaultsManager

    private enum CancelID { case timer, backgroundTimer }

    // バックグラウンドコールバック用の静的変数
    private static var backgroundTimerCallback: (() -> Void)?

    // 実行中のタスクを追跡するための変数
    private static var activeHapticTask: Task<Void, Error>?

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

                case .pauseTimer:
                    return handlePauseTimer(&state)

                case .resumeTimer:
                    return handleResumeTimer(&state)

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

                // 設定関連
                case .loadSettings:
                    return handleLoadSettings()

                case let .settingsLoaded(stopVibration, hapticType):
                    return handleSettingsLoaded(&state, stopVibration: stopVibration, hapticType: hapticType)
            }
        }
    }

    // ハプティックフィードバックを再生する関数
    private func playHapticFeedback(type: HapticType, stopAutomatically: Bool) async {
        let device = WKInterfaceDevice.current()

        if stopAutomatically {
            // 3秒間繰り返し振動を再生
            let startTime = Date()
            let endTime = startTime.addingTimeInterval(3.0)

            while Date() < endTime {
                // 選択された振動パターンを再生
                device.play(type.wkHapticType)

                // 次の振動までの間隔を待機
                try? await Task.sleep(for: .seconds(type.interval))

                // タスクがキャンセルされたかチェック
                if Task.isCancelled {
                    print("Haptic feedback task was cancelled")
                    return
                }
            }
        } else {
            // 設定がオフの場合は無限に振動を続ける
            while true {
                // 選択された振動パターンを再生
                device.play(type.wkHapticType)

                // 次の振動までの間隔を待機
                try? await Task.sleep(for: .seconds(type.interval))

                // タスクがキャンセルされたかチェック
                if Task.isCancelled {
                    print("Haptic feedback task was cancelled")
                    return
                }
            }
        }
    }

    // 振動を完全に停止する関数
    private func stopAllHapticFeedback() {
        // 既存のタスクをキャンセル
        Self.activeHapticTask?.cancel()
        Self.activeHapticTask = nil
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

        // バックグラウンドタイマー用コールバックを保存
        return .run { send in
            // 設定の読み込み
            await send(.loadSettings)

            // バックグラウンドコールバックを設定
            Self.backgroundTimerCallback = {
                // バックグラウンドでタイマーが完了したら通知
                Task { @MainActor in
                    await send(.backgroundTimerFinished)
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

        // 振動を停止
        stopAllHapticFeedback()

        // 拡張ランタイムセッションを停止
        ExtendedRuntimeManager.shared.stopSession()

        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.backgroundTimer)
        )
    }

    private func handlePauseTimer(_ state: inout State) -> Effect<Action> {
        state.isRunning = false

        // 一時停止時は残り時間を記録
        let remainingTime = state.remainingSeconds
        state.totalSeconds = remainingTime

        return .cancel(id: CancelID.timer)
    }

    private func handleResumeTimer(_ state: inout State) -> Effect<Action> {
        // 再開時は新たに開始時間と終了時間を設定
        let now = Date()
        state.startDate = now
        state.targetEndDate = now.addingTimeInterval(TimeInterval(state.totalSeconds))
        state.isRunning = true

        // 非同期クロージャーで使う値を先に取得
        let targetEndDate = state.targetEndDate
        let totalSeconds = state.totalSeconds

        // 拡張ランタイムセッションを再開
        return .run { send in
            // バックグラウンドコールバックを設定
            Self.backgroundTimerCallback = {
                // バックグラウンドでタイマーが完了したら通知
                Task { @MainActor in
                    await send(.backgroundTimerFinished)
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

            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.tick)
            }
        }
        .cancellable(id: CancelID.timer)
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

        // 実行中の振動タスクがあれば停止
        stopAllHapticFeedback()

        // 拡張ランタイムセッションを停止
        ExtendedRuntimeManager.shared.stopSession()

        // 非同期クロージャーで使う値を先に取得（inoutパラメータを直接キャプチャできないため）
        let selectedHapticType = state.selectedHapticType
        let stopVibrationAutomatically = state.stopVibrationAutomatically

        return .run { _ in
            // 既存のタスクを確実にキャンセル
            Self.activeHapticTask?.cancel()

            // 新しいタスクを作成して保存
            Self.activeHapticTask = Task {
                // ハプティックフィードバックを再生
                await playHapticFeedback(
                    type: selectedHapticType,
                    stopAutomatically: stopVibrationAutomatically
                )
            }

            // タスクが完了するまで待機
            do {
                try await Self.activeHapticTask?.value
            } catch {
                print("Haptic task was cancelled or failed: \(error)")
            }
        }
        .cancellable(id: CancelID.timer)
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

        // 実行中の振動タスクがあれば停止
        stopAllHapticFeedback()

        // 拡張ランタイムセッションを停止
        ExtendedRuntimeManager.shared.stopSession()

        // 非同期クロージャーで使う値を先に取得
        let selectedHapticType = state.selectedHapticType
        let stopVibrationAutomatically = state.stopVibrationAutomatically

        // ここで振動を開始
        return .run { _ in
            print("Starting haptic feedback from background timer completion")

            // 既存のタスクを確実にキャンセル
            Self.activeHapticTask?.cancel()

            // 新しいタスクを作成して保存
            Self.activeHapticTask = Task {
                // ハプティックフィードバックを再生
                await playHapticFeedback(
                    type: selectedHapticType,
                    stopAutomatically: stopVibrationAutomatically
                )
            }

            // タスクが完了するまで待機
            do {
                try await Self.activeHapticTask?.value
            } catch {
                print("Background haptic task was cancelled or failed: \(error)")
            }
        }
        .cancellable(id: CancelID.backgroundTimer)
    }

    private func handleDismissCompletionView(_ state: inout State) -> Effect<Action> {
        // 完了情報をリセット
        state.completionDate = nil

        // コールバックをクリア
        Self.backgroundTimerCallback = nil

        // 振動を確実に停止（追加部分）
        stopAllHapticFeedback()

        // runを使って即座に振動を停止
        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.backgroundTimer),
            // 即座に振動を停止するrunエフェクトを追加
            .run { _ in
                // 直接既存のタスクを停止
                DispatchQueue.main.async {
                    Self.activeHapticTask?.cancel()
                    Self.activeHapticTask = nil
                }
            }
        )
    }

    // MARK: - アクション処理メソッド - バックグラウンド/設定

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

    private func handleLoadSettings() -> Effect<Action> {
        .run { send in
            let stopVibration = userDefaultsManager
                .object(forKey: .stopVibrationAutomatically) as? Bool ?? true
            let typeRaw = userDefaultsManager.object(forKey: .hapticType) as? String
            let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? HapticType.standard
            await send(.settingsLoaded(stopVibration: stopVibration, hapticType: hapticType))
        }
    }

    private func handleSettingsLoaded(
        _ state: inout State,
        stopVibration: Bool,
        hapticType: HapticType
    ) -> Effect<Action> {
        state.stopVibrationAutomatically = stopVibration
        state.selectedHapticType = hapticType
        return .none
    }
}
