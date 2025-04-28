#if DEBUG

    import Dependencies
    import Foundation
    import SCProtocol
    import WatchKit

    // Preview用のHapticsService実装
    public class PreviewHapticsService: HapticsServiceProtocol {
        public init() {}

        public func play(_ type: Int) {
            // プレビューでは実際の触覚フィードバックを再生せず、ログ出力などで代替
            print("PreviewHapticsService: Playing haptic type (Int): \(type)")
        }

        func play(_ type: WKHapticType) async {
            // 実際の振動は行わず、コンソールにログを出力する
            let typeName = hapticTypeName(type)
            print("🫨 [プレビュー] HapticsService: 再生 \(typeName)") // ログ出力
        }

        // WKHapticType から可読な名前を取得するヘルパー (任意)
        private func hapticTypeName(_ type: WKHapticType) -> String {
            switch type {
                // Keep only cases mapped from HapticType enum
                case .success: return "Success"
                case .retry: return "Retry"
                case .directionUp: return "DirectionUp"
                @unknown default:
                    return "Unknown (\(type.rawValue))"
            }
        }
    }

#endif
