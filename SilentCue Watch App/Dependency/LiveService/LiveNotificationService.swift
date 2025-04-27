import ComposableArchitecture
import Foundation
import UserNotifications
import WatchKit
import XCTestDynamicOverlay

/// アプリの通知管理を行うクラス (ライブ実装)
final class LiveNotificationService: NotificationServiceProtocol {
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

    init() {
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
        UNUserNotificationCenter.current().setNotificationCategories([timerCompletedCategory])
    }

    // MARK: - プロトコルメソッド

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
}

// TestDependencyKey を使用して testValue を定義
extension LiveNotificationService: TestDependencyKey {
    static let testValue: NotificationServiceProtocol = {
        struct UnimplementedNotificationService: NotificationServiceProtocol {
            func requestAuthorization(completion: @escaping (Bool) -> Void) {
                XCTFail("\(Self.self).requestAuthorization は未実装です")
                completion(false)
            }

            func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
                XCTFail("\(Self.self).checkAuthorizationStatus は未実装です")
                completion(false)
            }

            func scheduleTimerCompletionNotification(at _: Date, minutes _: Int) {
                XCTFail("\(Self.self).scheduleTimerCompletionNotification は未実装です")
            }

            func cancelTimerCompletionNotification() {
                XCTFail("\(Self.self).cancelTimerCompletionNotification は未実装です")
            }
        }
        return UnimplementedNotificationService()
    }()
}
