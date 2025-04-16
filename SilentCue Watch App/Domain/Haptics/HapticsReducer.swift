import ComposableArchitecture
import Foundation
import WatchKit

/// ハプティックスに関連するすべての機能を管理するReducer
struct HapticsReducer: Reducer {
    typealias State = HapticsState
    typealias Action = HapticsAction

    private enum CancelID { case haptic, preview }

    // 実行中のタスクを追跡するための変数
    private static var activeHapticTask: Task<Void, Error>?

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .startHaptic(type):
                    return handleStartHaptic(&state, type: type)

                case .stopHaptic:
                    return handleStopHaptic(&state)

                case let .updateHapticSettings(type, stopAutomatically):
                    return handleUpdateHapticSettings(&state, type: type, stopAutomatically: stopAutomatically)

                case let .previewHaptic(type):
                    return handlePreviewHaptic(&state, type: type)

                case .previewHapticCompleted:
                    return handlePreviewHapticCompleted(&state)
            }
        }
    }

    // MARK: - 振動制御

    private func handleStartHaptic(_ state: inout State, type: HapticType) -> Effect<Action> {
        // 既に実行中なら停止
        if state.isActive {
            stopAllHapticFeedback()
        }

        state.isActive = true
        state.hapticType = type

        return .run { [stopAutomatically = state.stopAutomatically] _ in
            // 既存のタスクを確実にキャンセル
            Self.activeHapticTask?.cancel()

            // 新しいタスクを作成して保存
            Self.activeHapticTask = Task {
                // ハプティックフィードバックを再生
                await playHapticFeedback(
                    type: type,
                    stopAutomatically: stopAutomatically
                )
            }

            // タスクが完了するまで待機
            do {
                try await Self.activeHapticTask?.value
            } catch {
                print("Haptic task was cancelled or failed: \(error)")
            }
        }
        .cancellable(id: CancelID.haptic)
    }

    private func handleStopHaptic(_ state: inout State) -> Effect<Action> {
        state.isActive = false
        stopAllHapticFeedback()

        return .cancel(id: CancelID.haptic)
    }

    // MARK: - 設定

    private func handleUpdateHapticSettings(
        _ state: inout State,
        type: HapticType,
        stopAutomatically: Bool
    ) -> Effect<Action> {
        state.hapticType = type
        state.stopAutomatically = stopAutomatically
        return .none
    }

    // MARK: - プレビュー

    private func handlePreviewHaptic(_ state: inout State, type: HapticType) -> Effect<Action> {
        // プレビュー中なら先に既存のプレビューを停止
        if state.isPreviewingHaptic {
            // プレビューをキャンセル
            return .merge(
                .cancel(id: CancelID.preview),
                .run { send in
                    // 短い遅延を入れて確実に前のタスクが終了してから新しいタスクを開始
                    try? await Task.sleep(for: .milliseconds(50))
                    await send(.previewHaptic(type))
                }
            )
        }
        
        // プレビュー中フラグを設定
        state.isPreviewingHaptic = true

        return .run { send in
            // プレビュー用の振動を再生
            let device = WKInterfaceDevice.current()

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
                    break
                }
            }

            await send(.previewHapticCompleted)
        }
        .cancellable(id: CancelID.preview)
    }

    private func handlePreviewHapticCompleted(_ state: inout State) -> Effect<Action> {
        state.isPreviewingHaptic = false
        return .none
    }

    // MARK: - ユーティリティメソッド

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
}
