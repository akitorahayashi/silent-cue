#if DEBUG

    import Foundation
    import WatchKit
    import SCProtocol
    import Dependencies

    // Preview用のHapticsService実装
    public class PreviewHapticsService: HapticsServiceProtocol {
        // public var hapticEvents: [Int] = [] // Record played types if needed for preview inspection

        public init() {}

        public func play(_ type: Int) {
            // プレビューでは実際の触覚フィードバックを再生せず、ログ出力などで代替
            print("PreviewHapticsService: Playing haptic type (Int): \(type)")
            // hapticEvents.append(type)
        }

        func play(_ type: WKHapticType) async {
            // 実際の振動は行わず、コンソールにログを出力する
            let typeName = hapticTypeName(type)
            print("🫨 [プレビュー] HapticsService: 再生 \(typeName)") // ログ出力
        }

        // WKHapticType から可読な名前を取得するヘルパー (任意)
        private func hapticTypeName(_ type: WKHapticType) -> String {
            switch type {
                case .notification: return "Notification"
                case .directionUp: return "DirectionUp"
                case .directionDown: return "DirectionDown"
                case .success: return "Success"
                case .failure: return "Failure"
                case .retry: return "Retry"
                case .start: return "Start"
                case .stop: return "Stop"
                case .click: return "Click"
                @unknown default:
                    // Handle potential future cases
                    return "Unknown (\(type.rawValue))"
            }
        }
    }

#endif
