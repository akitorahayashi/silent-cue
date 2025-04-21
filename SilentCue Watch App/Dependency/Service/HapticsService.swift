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

// MARK: - TCA 依存関係

extension DependencyValues {
    var hapticsService: HapticsServiceProtocol { // プロパティ名を変更、型とキーを更新
        get { self[HapticsServiceKey.self] }
        set { self[HapticsServiceKey.self] = newValue }
    }
}

private enum HapticsServiceKey: DependencyKey {
    static let liveValue: HapticsServiceProtocol = LiveHapticsService()

    #if DEBUG
        // Preview 実装は Preview Content 内の PreviewHapticsService.swift にある想定
        static let previewValue: HapticsServiceProtocol = PreviewHapticsService()
    #else
        // リリースビルドでは liveValue を使用します (PreviewHapticsService は DEBUG 専用のため)
        static let previewValue: HapticsServiceProtocol = LiveHapticsService()
    #endif
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
