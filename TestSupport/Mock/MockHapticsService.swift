import Foundation
@testable import SilentCue_Watch_App // Import the main module to access the protocol
import WatchKit // For WKHapticType

/// HapticsServiceProtocol のモック実装
class MockHapticsService: HapticsServiceProtocol {
    // MARK: - 呼び出し記録

    var playCallCount = 0
    var lastPlayedHapticType: WKHapticType? = nil
    var playedHapticTypes: [WKHapticType] = []

    // MARK: - Protocol Conformance

    func play(_ type: WKHapticType) async {
        playCallCount += 1
        lastPlayedHapticType = type
        playedHapticTypes.append(type)
        // 非同期処理のシミュレーションが必要な場合は Task.sleep を使用できます
        // try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機など
    }

    // MARK: - テスト用リセット

    func reset() {
        playCallCount = 0
        lastPlayedHapticType = nil
        playedHapticTypes = []
    }
}
