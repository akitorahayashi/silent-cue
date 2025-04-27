import ComposableArchitecture
import Foundation
import UserNotifications
import WatchKit
import XCTestDynamicOverlay
import Dependencies
import SCProtocol

public class LiveNotificationService: NotificationServiceProtocol {
    /// 通知カテゴリの識別子
    private enum NotificationCategory: String {
        case timerCompleted = "TIMER_COMPLETED_CATEGORY"
    }

    /// 通知アクションの識別子
    private enum NotificationAction: String {
        case open = "OPEN_ACTION"
    }

    /// 通知識別子
    private enum NotificationIdentifier: String {
        case timerCompleted = "TIMER_COMPLETED_NOTIFICATION"
    }

    private let notificationCenter: UNUserNotificationCenter

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        setupNotificationCategories()
    }

    /// 通知カテゴリの設定
    private func setupNotificationCategories() {
        // タイマー完了時のアクション設定
        let openAction = UNNotificationAction(
            identifier: NotificationAction.open.rawValue,
            title: "アプリを開く",
            options: [.foreground]
        )

        // タイマー完了カテゴリの設定
        let timerCompletedCategory = UNNotificationCategory(
            identifier: NotificationCategory.timerCompleted.rawValue,
            actions: [openAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // 通知センターにカテゴリを登録
        notificationCenter.setNotificationCategories([timerCompletedCategory])
    }

    // MARK: - プロトコルメソッド

    public func requestAuthorization() async -> Bool {
        do {
            // .provisional オプションは、ユーザーに許可を求めずに暫定的に通知を送信する権限
            // .sound, .alert, .badge は標準的な通知権限
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            print("通知許可リクエスト結果: \(granted)")
            return granted
        } catch {
            print("通知許可リクエストエラー: \(error)")
            return false
        }
    }

    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationCenter.notificationSettings().authorizationStatus
    }

    public func add(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger) async throws {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await notificationCenter.add(request)
            print("通知リクエスト追加成功: ID \(identifier)")
        } catch {
            print("通知リクエスト追加エラー: ID \(identifier), エラー: \(error)")
            throw error // エラーを再スロー
        }
    }

    public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("保留中の通知リクエスト削除: IDs \(identifiers)")
    }

    public func removeAllPendingNotificationRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("全ての保留中の通知リクエスト削除")
    }

    func scheduleTimerCompletionNotification(at targetDate: Date, minutes: Int) {
        // 通知内容の設定
        let content = UNMutableNotificationContent()
        content.title = "タイマー完了"
        content.body = "\(minutes)分のタイマーが完了しました"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.timerCompleted.rawValue

        // 通知をスケジュール
        scheduleNotification(
            with: content,
            identifier: NotificationIdentifier.timerCompleted.rawValue,
            triggerDate: targetDate
        )
    }

    func cancelTimerCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.timerCompleted.rawValue]
        )
    }

    /// 通知をスケジュール
    private func scheduleNotification(with content: UNNotificationContent, identifier: String, triggerDate: Date) {
        // 日付トリガーの作成
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        // 通知リクエストの作成
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // 通知のスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("通知スケジュールエラー: \(error)")
            }
        }
    }

    // MARK: - Helper Methods (Private or Internal)
    // These might be useful for creating content or triggers if needed internally

    // Example: Creates standard notification content
    private func createNotificationContent(title: String, body: String, sound: UNNotificationSound = .default) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        return content
    }

    // Example: Creates a time interval trigger
    private func createTimeIntervalTrigger(timeInterval: TimeInterval, repeats: Bool = false) -> UNTimeIntervalNotificationTrigger {
        return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
    }
}

// MARK: - UNUserNotificationCenter Extension (Optional)
// If frequently used custom logic is needed, an extension can be helpful.
extension UNUserNotificationCenter {
    // Convenience method example (consider if it truly simplifies things)
    func addNotification(identifier: String, title: String, body: String, timeInterval: TimeInterval, sound: UNNotificationSound = .default) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await self.add(request)
    }
}
