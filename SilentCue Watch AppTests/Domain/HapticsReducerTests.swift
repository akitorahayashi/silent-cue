import ComposableArchitecture
import SCMock
import SCProtocol
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class HapticsReducerTests: XCTestCase {
    func testUpdateSettings() async {
        let store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() }
        )

        await store.send(CoordinatorAction.haptics(.updateHapticSettings(
            type: HapticType.strong
        ))) { state in
            state.haptics.hapticType = HapticType.strong
        }
        await store.finish() // Add finish for potential effects
    }

    func testStartAndStopHaptic() async {
        let clock = TestClock()

        let store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() },
            withDependencies: { dependencies in
                dependencies.hapticsService = MockHapticsService()
                dependencies.continuousClock = clock
                dependencies.date = .constant(Date(timeIntervalSince1970: 0))
            }
        )

        // Hapticを開始
        await store.send(CoordinatorAction.haptics(.startHaptic(HapticType.weak))) { state in
            state.haptics.isActive = true
            state.haptics.hapticType = HapticType.weak
        }
        // Effect.run は実行されるが、Task {} の中身は通常実行されない（TestClockなどが必要）
        // TestClockを使って時間依存の処理をテストする
        await clock.advance(by: .seconds(1)) // Advance time if needed for effects

        // Hapticを停止
        await store.send(CoordinatorAction.haptics(.stopHaptic)) { state in
            state.haptics.isActive = false
        }
        // .stopHapticで .cancel(id: .haptic) が発行されることを確認
        // TestStoreが自動でキャンセルをハンドルしてくれる

        // エフェクト完了待ち (startHapticとstopHaptic)
        await store.finish()
    }
}
