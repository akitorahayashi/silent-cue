import ComposableArchitecture
import Foundation
import WatchKit

/// 設定画面の機能を管理するReducer
struct SettingsReducer: Reducer {
    typealias State = SettingsState
    typealias Action = SettingsAction

    private enum CancelID { case hapticPreview }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.userDefaultsService) var userDefaultsService
            @Dependency(\.hapticsService) var hapticsService

            switch action {
                case .loadSettings:
                    return .run { send in
                        let typeRaw = userDefaultsService.object(forKey: .hapticType) as? String
                        let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? HapticType.standard
                        await send(.settingsLoaded(hapticType: hapticType))
                    }

                case let .settingsLoaded(hapticType):
                    state.selectedHapticType = hapticType
                    state.isSettingsLoaded = true
                    return .none

                case let .selectHapticType(type):
                    state.selectedHapticType = type
                    // タイプを選択したら自動的にプレビューと設定の保存
                    return .merge(
                        .run { [selectedType = state.selectedHapticType] _ in
                            userDefaultsService.set(selectedType.rawValue, forKey: .hapticType)
                        },
                        .send(.previewHapticFeedback(type))
                    )

                case let .previewHapticFeedback(hapticType):
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
                            // Use injected hapticsService
                            await hapticsService.play(hapticType.wkHapticType)

                            // 3秒間繰り返し振動を再生
                            let startTime = Date()
                            let endTime = startTime.addingTimeInterval(3.0)

                            while Date() < endTime {
                                // 選択された振動パターンを再生
                                await hapticsService.play(hapticType.wkHapticType)

                                // 次の振動までの間隔を待機
                                try await Task.sleep(for: .seconds(hapticType.interval))
                            }

                            // プレビュー完了アクションを送信
                            await send(.previewHapticCompleted)
                        }
                        .cancellable(id: CancelID.hapticPreview)
                    )

                case .previewHapticCompleted:
                    return .send(.previewingHapticChanged(false))

                case let .previewingHapticChanged(isPreviewingHaptic):
                    state.isPreviewingHaptic = isPreviewingHaptic
                    return .none

                case .saveSettings:
                    // This action is now handled inline within .selectHapticType effect
                    // Or, if called directly, needs access to the dependency
                    return .run { [selectedType = state.selectedHapticType] _ in
                        userDefaultsService.set(selectedType.rawValue, forKey: .hapticType)
                    }

                case .backButtonTapped:
                    return .none
            }
        }
    }
}
