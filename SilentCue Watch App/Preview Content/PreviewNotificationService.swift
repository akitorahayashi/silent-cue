#if DEBUG

    import Foundation

    struct PreviewNotificationService: NotificationServiceProtocol {
        func requestAuthorization(completion: @escaping (Bool) -> Void) {
            print("🔔 [プレビュー] NotificationService: requestAuthorization 呼び出し。許可を付与します。")
            // プレビューでは常に許可されている状態をシミュレート
            DispatchQueue.main.async {
                completion(true)
            }
        }

        func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
            print("🔔 [プレビュー] NotificationService: checkAuthorizationStatus 呼び出し。許可済みを報告します。")
            // プレビューでは常に許可されている状態をシミュレート
            DispatchQueue.main.async {
                completion(true)
            }
        }

        func scheduleTimerCompletionNotification(at targetDate: Date, minutes: Int) {
            print(
                "🔔 [プレビュー] NotificationService: scheduleTimerCompletionNotification 呼び出し。ターゲット: \(targetDate), 分: \(minutes)"
            )
            // プレビューでは実際のスケジュールは行わない
        }

        func cancelTimerCompletionNotification() {
            print("🔔 [プレビュー] NotificationService: cancelTimerCompletionNotification 呼び出し。")
            // プレビューでは実際のキャンセルは行わない
        }
    }

#endif
