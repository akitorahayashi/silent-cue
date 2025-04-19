#if DEBUG

struct PreviewNotificationService: NotificationServiceProtocol {
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        print("वुड [Preview] NotificationService: requestAuthorization called. Granting permission.")
        // プレビューでは常に許可されている状態をシミュレート
        DispatchQueue.main.async {
            completion(true)
        }
    }

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        print("वुड [Preview] NotificationService: checkAuthorizationStatus called. Reporting authorized.")
        // プレビューでは常に許可されている状態をシミュレート
        DispatchQueue.main.async {
            completion(true)
        }
    }

    func scheduleTimerCompletionNotification(at targetDate: Date, minutes: Int) {
        print("वुड [Preview] NotificationService: scheduleTimerCompletionNotification called. Target: \(targetDate), Minutes: \(minutes)")
        // プレビューでは実際のスケジュールは行わない
    }

    func cancelTimerCompletionNotification() {
        print("वुड [Preview] NotificationService: cancelTimerCompletionNotification called.")
        // プレビューでは実際のキャンセルは行わない
    }
}

#endif 