import Foundation

protocol NotificationServiceProtocol {
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func scheduleTimerCompletionNotification(at targetDate: Date, minutes: Int)
    func cancelTimerCompletionNotification()
}
