import Dependencies
import Foundation
import SCProtocol
import WatchKit

public class MockHapticsService: HapticsServiceProtocol {
    // Track played haptic types for verification
    public var playedHapticTypes: [Int] = []
    public var playCallCount = 0
    public var lastPlayedHapticType: WKHapticType?

    public init() {}

    public func play(_ type: Int) {
        playCallCount += 1
        playedHapticTypes.append(type)
        // Attempt to convert Int to WKHapticType and update lastPlayedHapticType
        if let hapticType = WKHapticType(rawValue: type) {
            lastPlayedHapticType = hapticType
        }
        print("MockHapticsService: Playing haptic type (Int): \(type)")
    }

    // Reset function for testing
    public func reset() {
        playedHapticTypes.removeAll()
        playCallCount = 0
        lastPlayedHapticType = nil
    }

    public func play(_ type: WKHapticType) async {
        playCallCount += 1
        lastPlayedHapticType = type
        playedHapticTypes.append(type.rawValue)
        // 非同期処理のシミュレーションが必要な場合は Task.sleep を使用できます
        // try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機など
    }
}
