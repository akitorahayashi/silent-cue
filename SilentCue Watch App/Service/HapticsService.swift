import Dependencies
import WatchKit
import XCTestDynamicOverlay

final class LiveHapticsService: HapticsServiceProtocol {
    func play(_ type: WKHapticType) async {
        // WatchKit で必要な場合はメインスレッドで実行されることを保証
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

private enum HapticsServiceKey: DependencyKey { // キーenum名を変更
    static let liveValue: HapticsServiceProtocol = LiveHapticsService() // 新しいクラスとプロトコルを使用

    // Preview実装 - liveValue を使用 (モックはテストターゲット専用)
    static let previewValue: HapticsServiceProtocol = Self.liveValue
}

// TestDependencyKey を使用して testValue を定義
extension LiveHapticsService: TestDependencyKey { // 拡張ターゲットを更新
    static let testValue: HapticsServiceProtocol = { // プロトコル型を更新
        struct UnimplementedHapticsService: HapticsServiceProtocol { // 構造体名を変更、新しいプロトコルに準拠
            func play(_ type: WKHapticType) async {
                XCTFail("\(Self.self).play はタイプ \(type.rawValue) に対して未実装です")
            }
        }
        return UnimplementedHapticsService()
    }()
}
