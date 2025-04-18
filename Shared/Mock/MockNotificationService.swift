import Foundation
@testable import SilentCue_Watch_App // Import the main module to access the protocol
import UserNotifications

/// NotificationServiceProtocol のモック実装
class MockNotificationService: NotificationServiceProtocol {
    // MARK: - 呼び出し記録

    var requestAuthorizationCallCount = 0
    var checkAuthorizationStatusCallCount = 0
    var scheduleTimerCompletionNotificationCallCount = 0
    var lastScheduledNotificationParams: (targetDate: Date, minutes: Int)? = nil
    var cancelTimerCompletionNotificationCallCount = 0

    // MARK: - スタブ設定

    /// requestAuthorization の完了ハンドラに渡す値（許可されたか）
    var requestAuthorizationGrantedResult: Bool = true
    /// requestAuthorization を非同期で完了させるか（テスト用）
    var completeRequestAuthorizationAsynchronously = false

    /// checkAuthorizationStatus の完了ハンドラに渡す値（許可されているか）
    var checkAuthorizationStatusResult: Bool = true
    /// checkAuthorizationStatus を非同期で完了させるか（テスト用）
    var completeCheckAuthorizationStatusAsynchronously = false

    // MARK: - Protocol Conformance

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        requestAuthorizationCallCount += 1
        if completeRequestAuthorizationAsynchronously {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    completion(self.requestAuthorizationGrantedResult)
                }
            }
        } else {
            completion(requestAuthorizationGrantedResult)
        }
    }

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        checkAuthorizationStatusCallCount += 1
        if completeCheckAuthorizationStatusAsynchronously {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    completion(self.checkAuthorizationStatusResult)
                }
            }
        } else {
            completion(checkAuthorizationStatusResult)
        }
    }

    func scheduleTimerCompletionNotification(at targetDate: Date, minutes: Int) {
        scheduleTimerCompletionNotificationCallCount += 1
        lastScheduledNotificationParams = (targetDate, minutes)
        print("[MockNotificationService] Scheduling notification for \(minutes) min at \(targetDate)")
    }

    func cancelTimerCompletionNotification() {
        cancelTimerCompletionNotificationCallCount += 1
        print("[MockNotificationService] Cancelling notification")
    }

    // MARK: - テスト用リセット

    func reset() {
        requestAuthorizationCallCount = 0
        checkAuthorizationStatusCallCount = 0
        scheduleTimerCompletionNotificationCallCount = 0
        lastScheduledNotificationParams = nil
        cancelTimerCompletionNotificationCallCount = 0

        requestAuthorizationGrantedResult = true
        completeRequestAuthorizationAsynchronously = false
        checkAuthorizationStatusResult = true
        completeCheckAuthorizationStatusAsynchronously = false
    }
}
