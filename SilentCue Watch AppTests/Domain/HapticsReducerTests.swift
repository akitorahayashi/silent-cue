import ComposableArchitecture
import SCMock
import SCProtocol
import SCShared
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class HapticsReducerTests: XCTestCase {
    var store: TestStore<CoordinatorState, CoordinatorAction>!
    var clock: TestClock<Duration>!

    override func setUp() {
        super.setUp()
        clock = TestClock<Duration>()
        store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() },
            withDependencies: {
                $0.hapticsService = MockHapticsService()
                $0.continuousClock = self.clock
                $0.date = .constant(Date(timeIntervalSince1970: 0))
            }
        )
    }

    override func tearDown() {
        store = nil
        clock = nil
        super.tearDown()
    }

    func testUpdateSettings() async {
        await store.send(CoordinatorAction.haptics(.updateHapticSettings(
            type: HapticType.strong
        ))) { state in
            state.haptics.hapticType = HapticType.strong
        }
        await store.finish()
    }

    func testStartAndStopHaptic() async {
        // Hapticを開始
        await store.send(CoordinatorAction.haptics(.startHaptic(HapticType.weak))) { state in
            state.haptics.isActive = true
            state.haptics.hapticType = HapticType.weak
        }

        await clock.advance(by: .seconds(1))

        // Hapticを停止
        await store.send(CoordinatorAction.haptics(.stopHaptic)) { state in
            state.haptics.isActive = false
        }

        await store.finish()
    }
}
