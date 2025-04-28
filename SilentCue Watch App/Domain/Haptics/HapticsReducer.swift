import ComposableArchitecture
import Dependencies
import Foundation
import WatchKit

struct HapticsReducer: Reducer {
    typealias State = HapticsState
    typealias Action = HapticsAction

    private enum CancelID { case haptic, preview }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.hapticsService) var hapticsService

    var body: some ReducerOf<Self> {
        Reduce { state, action in

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
                        .run { [type] _ in
                            hapticsService.play(type.wkHapticType.rawValue)
                        }
                        .cancellable(id: CancelID.haptic)
                    )

                case .stopHaptic:
                    state.isActive = false
                    return .cancel(id: CancelID.haptic)

                case let .updateHapticSettings(type):
                    state.hapticType = type
                    return .none
            }
        }
    }
}
