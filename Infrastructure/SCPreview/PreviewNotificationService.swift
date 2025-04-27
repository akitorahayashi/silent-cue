#if DEBUG

    import Foundation
    import SCProtocol
    import Dependencies
    import UserNotifications // Import if needed for types like UNAuthorizationStatus

    // Preview用のNotificationService実装
    public class PreviewNotificationService: NotificationServiceProtocol {
        // Track status or requests if needed for preview inspection
        public var authorizationStatus: UNAuthorizationStatus = .notDetermined
        private var addedRequests: [String] = []

        public init() {}

        // --- Protocol Methods ---
        public func requestAuthorization() async -> Bool {
            // プレビューでは常に許可されたと仮定、または特定の状態をシミュレート
            print("PreviewNotificationService: Requesting authorization (simulating granted).")
            authorizationStatus = .authorized
            return true
        }

        public func getAuthorizationStatus() async -> UNAuthorizationStatus {
            print("PreviewNotificationService: Getting authorization status: \(authorizationStatus).")
            return authorizationStatus
        }

        public func add(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger) async throws {
            // プレビューでは実際には追加せず、ログ出力などで代替
            print("PreviewNotificationService: Adding notification request: ID \(identifier)")
            addedRequests.append(identifier)
        }

        public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            print("PreviewNotificationService: Removing pending requests: IDs \(identifiers)")
            addedRequests.removeAll { identifiers.contains($0) }
        }

        public func removeAllPendingNotificationRequests() {
            print("PreviewNotificationService: Removing all pending requests.")
            addedRequests.removeAll()
        }
    }

#endif
