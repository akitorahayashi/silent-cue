import XCTestDynamicOverlay
import Dependencies
import WatchKit

final class LiveHapticsService: HapticsServiceProtocol {
    func play(_ type: WKHapticType) async {
        // WatchKit で必要な場合はメインスレッドで実行されることを保証
        await MainActor.run {
            WKInterfaceDevice.current().play(type)
        }
    }

    // TCAのための public init
    public init() {}
}

// MARK: - TCA Dependency

extension DependencyValues {
    var hapticsService: HapticsServiceProtocol { // Rename property, update type and key
        get { self[HapticsServiceKey.self] }
        set { self[HapticsServiceKey.self] = newValue }
    }
}

private enum HapticsServiceKey: DependencyKey { // Rename key enum
    static let liveValue: HapticsServiceProtocol = LiveHapticsService() // Use new class and protocol

    // Preview実装 - No-op実装を使用
    static let previewValue: HapticsServiceProtocol = NoopHapticsService()
}

// TestDependencyKey を使用して testValue を定義
extension LiveHapticsService: TestDependencyKey { // Update extension target
    static let testValue: HapticsServiceProtocol = { // Update protocol type
        struct UnimplementedHapticsService: HapticsServiceProtocol { // Rename struct, conform to new protocol
            func play(_ type: WKHapticType) async {
                XCTFail("\(Self.self).play is unimplemented for type \(type.rawValue)")
            }
        }
        return UnimplementedHapticsService()
    }()
}
