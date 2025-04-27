import Dependencies
import WatchKit
import XCTestDynamicOverlay

final class LiveHapticsService: HapticsServiceProtocol {
    func play(_ type: WKHapticType) async {
        await MainActor.run {
            WKInterfaceDevice.current().play(type)
        }
    }
}

// TestDependencyKey を使用して testValue を定義
extension LiveHapticsService: TestDependencyKey {
    static let testValue: HapticsServiceProtocol = {
        struct UnimplementedHapticsService: HapticsServiceProtocol {
            func play(_ type: WKHapticType) async {
                XCTFail("\(Self.self).play はタイプ \(type.rawValue) に対して未実装です")
            }
        }
        return UnimplementedHapticsService()
    }()
}
