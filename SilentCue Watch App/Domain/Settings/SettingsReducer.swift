import ComposableArchitecture
import Foundation
import SCProtocol
import SCShared
import WatchKit

struct SettingsReducer: Reducer {
    typealias State = SettingsState
    typealias Action = SettingsAction

    private enum CancelID {
        case saveSettings
        case hapticPreviewTimer
        case hapticPreviewTimeout
    }

    @Dependency(\.userDefaultsService) var userDefaultsService
    @Dependency(\.hapticsService) var hapticsService
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in

            switch action {
                case .loadSettings:
                    return .run { send in
                        let typeRaw = userDefaultsService.object(forKey: UserDefaultsKeys.hapticType) as? String
                        let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? HapticType.standard
                        await send(.settingsLoaded(hapticType: hapticType))
                    }

                case let .settingsLoaded(hapticType):
                    state.selectedHapticType = hapticType
                    state.isSettingsLoaded = true
                    return .none

                case let .selectHapticType(type):
                    let stopPreviewEffect: Effect<Action> = state.isPreviewingHaptic
                        ? .send(.stopHapticPreview)
                        : .none
                    state.selectedHapticType = type
                    return .merge(
                        stopPreviewEffect,
                        .send(.internal(.saveSettingsEffect)),
                        .send(.startHapticPreview(type))
                    )

                case let .startHapticPreview(hapticType):
                    guard !state.isPreviewingHaptic else { return .none }

                    state.isPreviewingHaptic = true

                    return .merge(
                        .run { _ in await hapticsService.play(hapticType.wkHapticType.rawValue) },

                        .run { send in
                            for await _ in clock.timer(interval: .seconds(hapticType.interval)) {
                                await send(.hapticPreviewTick)
                            }
                        }
                        .cancellable(id: CancelID.hapticPreviewTimer, cancelInFlight: true),

                        .run { send in
                            try await clock.sleep(for: .seconds(3))
                            await send(.stopHapticPreview)
                        }
                        .cancellable(id: CancelID.hapticPreviewTimeout, cancelInFlight: true)
                    )

                case .hapticPreviewTick:
                    guard state.isPreviewingHaptic else { return .none }
                    return .run { [selectedType = state.selectedHapticType] _ in
                        await hapticsService.play(selectedType.wkHapticType.rawValue)
                    }

                case .stopHapticPreview:
                    guard state.isPreviewingHaptic else { return .none }
                    state.isPreviewingHaptic = false
                    return .merge(
                        .cancel(id: CancelID.hapticPreviewTimer),
                        .cancel(id: CancelID.hapticPreviewTimeout)
                    )

                case let .previewHapticFeedback(type):
                    return .send(.startHapticPreview(type))

                case .previewHapticCompleted:
                    return .send(.stopHapticPreview)

                case .saveSettings:
                    return .send(.internal(.saveSettingsEffect))

                case .backButtonTapped:
                    return state.isPreviewingHaptic ? .send(.stopHapticPreview) : .none

                case let .internal(internalAction):
                    switch internalAction {
                        case .saveSettingsEffect:
                            return .run { [selectedType = state.selectedHapticType] _ in
                                userDefaultsService.set(selectedType.rawValue, forKey: .hapticType)
                            }
                            .cancellable(id: CancelID.saveSettings, cancelInFlight: true)
                    }
            }
        }
    }
}
