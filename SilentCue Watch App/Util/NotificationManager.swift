import Foundation
import UserNotifications
import WatchKit

/// アプリの通知管理を行うクラス
class NotificationManager {
    static let shared = NotificationManager()
    private init() {
        // 通知カテゴリの設定
        setupNotificationCategories()
    }

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

    /// UIテスト実行中かどうかのフラグ
    private var isNotificationsDisabled: Bool {
        // ProcessInfo からテスト実行フラグを取得
        ProcessInfo.processInfo
            .environment[AppEnvironment.EnvKeys.disableNotificationsForTesting.rawValue] == AppEnvironment.EnvValues.yes.rawValue
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

    /// 通知許可をリクエスト
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

    /// 通知許可状態を確認
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                completion(isAuthorized)
            }
        }
    }

    /// タイマー完了通知をスケジュール
    /// - Parameters:
    ///   - targetDate: タイマー完了予定時刻
    ///   - minutes: タイマー設定分数
    func scheduleTimerCompletionNotification(at targetDate: Date, minutes: Int) {
        // UIテスト実行中は通知をスケジュールしない
        if isNotificationsDisabled {
            print("通知はテスト中のため無効化されています")
            return
        }

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

    /// 予定済みの通知をキャンセル
    func cancelTimerCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.timerCompleted.rawValue]
        )
    }

    /// 通知をスケジュール
    private func scheduleNotification(with content: UNNotificationContent, identifier: String, triggerDate: Date) {
        // UIテスト実行中は通知をスケジュールしない（冗長なチェックだが安全のため）
        if isNotificationsDisabled {
            return
        }

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
