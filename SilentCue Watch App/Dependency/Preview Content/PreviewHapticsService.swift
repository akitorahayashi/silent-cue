#if DEBUG

    import Foundation
    import WatchKit

    struct PreviewHapticsService: HapticsServiceProtocol {
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
