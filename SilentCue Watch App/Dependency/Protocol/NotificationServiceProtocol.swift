import Foundation

/// 通知管理機能のインターフェース
protocol NotificationServiceProtocol {
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func scheduleTimerCompletionNotification(at targetDate: Date, minutes: Int)
    func cancelTimerCompletionNotification()
}
