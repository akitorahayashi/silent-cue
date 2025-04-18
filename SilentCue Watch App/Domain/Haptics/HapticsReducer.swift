import ComposableArchitecture
import Dependencies
import Foundation
import WatchKit

/// ハプティックスに関連するすべての機能を管理するReducer
struct HapticsReducer: Reducer {
    typealias State = HapticsState
    typealias Action = HapticsAction

    private enum CancelID { case haptic, preview }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.hapticsService) var hapticsService

            switch action {
                case let .startHaptic(type):
                    var effect = Effect<Action>.none
                    if state.isActive {
                        effect = .cancel(id: CancelID.haptic)
                    }
                    state.isActive = true
                    state.hapticType = type

                    return .merge(
                        effect,
                        .run { [type = state.hapticType] _ in
                            let startTime = Date()
                            let endTime = startTime.addingTimeInterval(3.0)

                            while Date() < endTime {
                                await hapticsService.play(type.wkHapticType)
                                try? await Task.sleep(for: .seconds(type.interval))
                                if Task.isCancelled {
                                    print("Haptic task cancelled in run loop")
                                    break
                                }
                            }
                        }
                        .cancellable(id: CancelID.haptic)
                    )

                case .stopHaptic:
                    state.isActive = false
                    return .cancel(id: CancelID.haptic)

                case let .updateHapticSettings(type):
                    state.hapticType = type
                    return .none

                case let .previewHaptic(type):
                    if state.isPreviewingHaptic {
                        return .merge(
                            .cancel(id: CancelID.preview),
                            .run { send in
                                try? await Task.sleep(for: .milliseconds(50))
                                await send(.previewHaptic(type))
                            }
                        )
                    }
                    state.isPreviewingHaptic = true

                    return .run { [type] send in
                        let startTime = Date()
                        let endTime = startTime.addingTimeInterval(3.0)

                        while Date() < endTime {
                            await hapticsService.play(type.wkHapticType)
                            try? await Task.sleep(for: .seconds(type.interval))
                            if Task.isCancelled {
                                print("Haptic preview task cancelled in run loop")
                                break
                            }
                        }
                        await send(.previewHapticCompleted)
                    }
                    .cancellable(id: CancelID.preview)

                case .previewHapticCompleted:
                    state.isPreviewingHaptic = false
                    return .none
            }
        }
    }
}
