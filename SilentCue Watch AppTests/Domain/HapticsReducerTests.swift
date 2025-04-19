import ComposableArchitecture
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class HapticsReducerTests: XCTestCase {
    func testUpdateSettings() async {
        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() }
        )

        await store.send(AppAction.haptics(.updateHapticSettings(
            type: HapticType.strong
        ))) { state in
            state.haptics.hapticType = HapticType.strong
        }
        await store.finish() // Add finish for potential effects
    }

    func testStartAndStopHaptic() async {
        // HapticsのEffect.runの中身（実際の振動）はテスト困難なため、
        // 状態変化とキャンセルIDの管理を中心にテストする

        // No-Op Haptics Service for this test
        struct NoOpHapticsService: HapticsServiceProtocol {
            func play(_: WKHapticType) async {}
        }

        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() },
            withDependencies: {
                $0.hapticsService = NoOpHapticsService()
            }
        )

        // Hapticを開始
        await store.send(AppAction.haptics(.startHaptic(HapticType.weak))) { state in
            state.haptics.isActive = true
            state.haptics.hapticType = HapticType.weak
        }
        // Effect.run は実行されるが、Task {} の中身は通常実行されない（TestClockなどが必要）
        // キャンセル可能であることのテストは可能

        // Hapticを停止
        await store.send(AppAction.haptics(.stopHaptic)) { state in
            state.haptics.isActive = false
        }
        // .stopHapticで .cancel(id: .haptic) が発行されることを確認
        // TestStoreが自動でキャンセルをハンドルしてくれる

        // エフェクト完了待ち (startHapticとstopHaptic)
        await store.finish()
    }
}
