import ComposableArchitecture
import Foundation
import WatchKit

/// 設定画面の機能を管理するReducer
struct SettingsReducer: Reducer {
    typealias State = SettingsState
    typealias Action = SettingsAction

    // Update CancelIDs
    private enum CancelID {
        case saveSettings
        case hapticPreviewTimer // For the repeating timer
        case hapticPreviewTimeout // For the 3-second timeout
    }

    // 依存関係を struct のプロパティとして宣言
    @Dependency(\.userDefaultsService) var userDefaultsService
    @Dependency(\.hapticsService) var hapticsService
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // @Dependency(\.userDefaultsService) var userDefaultsService // Reduceブロックから削除
            // @Dependency(\.hapticsService) var hapticsService // Reduceブロックから削除
            // @Dependency(\.continuousClock) var clock           // Reduceブロックから削除
            // 依存関係は struct のプロパティとしてアクセス可能

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
                    // 1. If previewing, stop the current one first.
                    let stopPreviewEffect: Effect<Action> = state.isPreviewingHaptic
                        ? .send(.stopHapticPreview)
                        : .none
                    // 2. Update state synchronously.
                    state.selectedHapticType = type
                    // 3. Return effects: stop (if needed), save, start new preview.
                    return .merge(
                        stopPreviewEffect,
                        .send(.internal(.saveSettingsEffect)),
                        .send(.startHapticPreview(type))
                    )

                // --- New Haptic Preview Flow ---
                case let .startHapticPreview(hapticType):
                    // Guard against starting if already previewing (should be stopped by selectHapticType)
                    guard !state.isPreviewingHaptic else { return .none }

                    state.isPreviewingHaptic = true

                    return .merge(
                        // 1. Play initial haptic immediately
                        .run { _ in await hapticsService.play(hapticType.wkHapticType) },

                        // 2. Start repeating timer
                        .run { send in
                            for await _ in clock.timer(interval: .seconds(hapticType.interval)) {
                                await send(.hapticPreviewTick)
                            }
                        }
                        .cancellable(id: CancelID.hapticPreviewTimer, cancelInFlight: true),

                        // 3. Start 3-second timeout
                        .run { send in
                            try await clock.sleep(for: .seconds(3))
                            await send(.stopHapticPreview)
                        }
                        .cancellable(id: CancelID.hapticPreviewTimeout, cancelInFlight: true)
                    )

                case .hapticPreviewTick:
                    // Only play haptic if still in preview mode
                    guard state.isPreviewingHaptic else { return .none }
                    // Use the currently selected type from state
                    return .run { [selectedType = state.selectedHapticType] _ in
                        await hapticsService.play(selectedType.wkHapticType)
                    }

                case .stopHapticPreview:
                    guard state.isPreviewingHaptic else { return .none } // Prevent redundant stops
                    state.isPreviewingHaptic = false
                    // Cancel both timer and timeout effects
                    return .merge(
                        .cancel(id: CancelID.hapticPreviewTimer),
                        .cancel(id: CancelID.hapticPreviewTimeout)
                    )

                // --- Deprecated Actions (Redirect or Ignore) ---
                case let .previewHapticFeedback(type):
                    // Redirect to new flow
                    return .send(.startHapticPreview(type))
                case .previewHapticCompleted:
                    // Can likely be ignored, or redirect to stop
                    return .send(.stopHapticPreview) // Or just .none
                case .saveSettings:
                    // Redirect to internal effect trigger
                    return .send(.internal(.saveSettingsEffect))

                case .backButtonTapped:
                    // Stop preview if active when navigating back
                    return state.isPreviewingHaptic ? .send(.stopHapticPreview) : .none

                // --- Internal Actions ---
                case let .internal(internalAction):
                    switch internalAction {
                        case .saveSettingsEffect:
                            // Save logic remains the same
                            return .run { [selectedType = state.selectedHapticType] _ in
                                userDefaultsService.set(selectedType.rawValue, forKey: .hapticType)
                            }
                            .cancellable(id: CancelID.saveSettings, cancelInFlight: true)
                    }
            }
        }
    }
}
