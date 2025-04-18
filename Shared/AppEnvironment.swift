import Foundation

/// アプリが使用する環境変数定数
enum AppEnvironment {
    enum EnvKeys: String {
        /// テスト中に通知を無効化
        case disableNotificationsForTesting = "DISABLE_NOTIFICATIONS_FOR_TESTING"
    }

    enum EnvValues: String {
        case yes = "YES"
        case no = "NO"
    }
}
