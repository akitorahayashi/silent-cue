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
                    return .run { send in
                        let stopVibration = userDefaultsManager
                            .object(forKey: .stopVibrationAutomatically) as? Bool ?? true
                        let typeRaw = userDefaultsManager.object(forKey: .hapticType) as? String
                        let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? HapticType.standard
                        await send(.settingsLoaded(stopVibration: stopVibration, hapticType: hapticType))
                    }

                case let .settingsLoaded(stopVibration, hapticType):
                    state.stopVibrationAutomatically = stopVibration
                    state.selectedHapticType = hapticType
                    state.hasLoaded = true
                    return .none

                case let .toggleStopVibrationAutomatically(value):
                    state.stopVibrationAutomatically = value
                    return .send(.saveSettings)

                case let .selectHapticType(type):
                    state.selectedHapticType = type
                    // タイプを選択したら自動的にプレビューと設定の保存
                    return .merge(
                        .send(.saveSettings),
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

                case .previewHapticCompleted:
                    // プレビュー完了アクションでフラグを更新
                    return .send(.previewingHapticChanged(false))

                case let .previewingHapticChanged(isPreviewingHaptic):
                    state.isPreviewingHaptic = isPreviewingHaptic
                    return .none

                case .saveSettings:
                    let stopAutoValue = state.stopVibrationAutomatically
                    let hapticTypeValue = state.selectedHapticType.rawValue

                    return .run { _ in
                        userDefaultsManager.set(stopAutoValue, forKey: .stopVibrationAutomatically)
                        userDefaultsManager.set(hapticTypeValue, forKey: .hapticType)
                    }

                case .backButtonTapped:
                    return .none
            }
        }
    }
}
