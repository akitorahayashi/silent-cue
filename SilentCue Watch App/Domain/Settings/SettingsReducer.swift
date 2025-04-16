import ComposableArchitecture
import Foundation
import WatchKit

/// 設定画面の機能を管理するReducer
struct SettingsReducer: Reducer {
    typealias State = SettingsState
    typealias Action = SettingsAction

    @Dependency(\.userDefaultsManager) var userDefaultsManager

    private enum CancelID { case hapticPreview }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case .loadSettings:
                    return handleLoadSettings()

                case let .settingsLoaded(hapticType):
                    return handleSettingsLoaded(&state, hapticType: hapticType)

                case let .selectHapticType(type):
                    return handleSelectHapticType(&state, type: type)

                case let .previewHapticFeedback(hapticType):
                    return handlePreviewHapticFeedback(&state, hapticType: hapticType)

                case .previewHapticCompleted:
                    return handlePreviewHapticCompleted()

                case let .previewingHapticChanged(isPreviewingHaptic):
                    return handlePreviewingHapticChanged(&state, isPreviewingHaptic: isPreviewingHaptic)

                case .saveSettings:
                    return handleSaveSettings(&state)

                case .backButtonTapped:
                    return handleBackButtonTapped()
            }
        }
    }

    // MARK: - 設定読み込み関連

    private func handleLoadSettings() -> Effect<Action> {
        .run { send in
            let typeRaw = userDefaultsManager.object(forKey: .hapticType) as? String
            let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? HapticType.standard
            await send(.settingsLoaded(hapticType: hapticType))
        }
    }

    private func handleSettingsLoaded(
        _ state: inout State,
        hapticType: HapticType
    ) -> Effect<Action> {
        state.selectedHapticType = hapticType
        state.isSettingsLoaded = true
        return .none
    }

    // MARK: - 設定変更関連

    private func handleSelectHapticType(_ state: inout State, type: HapticType) -> Effect<Action> {
        state.selectedHapticType = type
        // タイプを選択したら自動的にプレビューと設定の保存
        return .merge(
            .send(.saveSettings),
            .send(.previewHapticFeedback(type))
        )
    }

    private func handleSaveSettings(_ state: inout State) -> Effect<Action> {
        let hapticTypeValue = state.selectedHapticType.rawValue

        return .run { _ in
            userDefaultsManager.set(hapticTypeValue, forKey: .hapticType)
        }
    }

    // MARK: - プレビュー関連

    private func handlePreviewHapticFeedback(_ state: inout State, hapticType: HapticType) -> Effect<Action> {
        // 既にプレビュー中なら前のプレビューをキャンセル
        let cancelEffect: Effect<SettingsAction> = state.isPreviewingHaptic
            ? .cancel(id: CancelID.hapticPreview)
            : .none

        // 状態を更新し、新しいハプティックフィードバックを再生
        state.selectedHapticType = hapticType

        return .merge(
            cancelEffect,
            .send(.previewingHapticChanged(true)),
            .run { send in
                // Apple Watch向けのハプティックフィードバック
                let device = WKInterfaceDevice.current()

                // 3秒間繰り返し振動を再生
                let startTime = Date()
                let endTime = startTime.addingTimeInterval(3.0)

                while Date() < endTime {
                    // 選択された振動パターンを再生
                    device.play(hapticType.wkHapticType)

                    // 次の振動までの間隔を待機
                    try await Task.sleep(for: .seconds(hapticType.interval))
                }

                // プレビュー完了アクションを送信
                await send(.previewHapticCompleted)
            }
            .cancellable(id: CancelID.hapticPreview)
        )
    }

    private func handlePreviewHapticCompleted() -> Effect<Action> {
        // プレビュー完了アクションでフラグを更新
        .send(.previewingHapticChanged(false))
    }

    private func handlePreviewingHapticChanged(_ state: inout State, isPreviewingHaptic: Bool) -> Effect<Action> {
        state.isPreviewingHaptic = isPreviewingHaptic
        return .none
    }

    // MARK: - ナビゲーション関連

    private func handleBackButtonTapped() -> Effect<Action> {
        .none
    }
}
