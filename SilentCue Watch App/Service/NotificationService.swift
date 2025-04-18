import ComposableArchitecture
import Foundation
import UserNotifications
import WatchKit
import XCTestDynamicOverlay

/// アプリの通知管理を行うクラス (ライブ実装)
final class LiveNotificationService: NotificationServiceProtocol { // Rename class, conform to new protocol
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
        UNUserNotificationCenter.current().setNotificationCategories([timerCompletedCategory])
    }

    // MARK: - Protocol Methods

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    print("通知許可リクエストエラー: \(error)")
                    completion(false)
                    return
                }

                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                completion(isAuthorized)
            }
        }
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

    // public init (DependencyKey で使用するため)
    public init() {
        setupNotificationCategories()
    }
}

// MARK: - TCA Dependency

extension DependencyValues {
    var notificationService: NotificationServiceProtocol { // Rename property, update type and key
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}

private enum NotificationServiceKey: DependencyKey { // Rename key enum
    // ライブ実装を提供
    static let liveValue: NotificationServiceProtocol = LiveNotificationService() // Use new class and protocol

    // Preview実装を提供 (No-op)
    static let previewValue: NotificationServiceProtocol =
        NoopNotificationService() // Update to use renamed NoopNotificationService
}

// TestDependencyKey を使用して testValue を定義
// Note: previewValue takes precedence over testValue in Previews.
extension LiveNotificationService: TestDependencyKey { // Update extension target
    static let testValue: NotificationServiceProtocol = { // Update protocol type
        struct UnimplementedNotificationService: NotificationServiceProtocol { // Rename struct, conform to new protocol
            func requestAuthorization(completion: @escaping (Bool) -> Void) {
                XCTFail("\(Self.self).requestAuthorization is unimplemented")
                completion(false)
            }

            func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
                XCTFail("\(Self.self).checkAuthorizationStatus is unimplemented")
                completion(false)
            }

            func scheduleTimerCompletionNotification(at _: Date, minutes _: Int) {
                XCTFail("\(Self.self).scheduleTimerCompletionNotification is unimplemented")
            }

            func cancelTimerCompletionNotification() {
                XCTFail("\(Self.self).cancelTimerCompletionNotification is unimplemented")
            }
        }
        return UnimplementedNotificationService()
    }()
}
