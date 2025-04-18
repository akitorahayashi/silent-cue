import Foundation

/// アプリが使用する環境変数定数
enum SCAppEnvironment {
    enum EnvKeys: String {
        /// テスト中に通知を無効化
        case disableNotificationsForTesting = "DISABLE_NOTIFICATIONS_FOR_TESTING"
    }

    enum EnvValues: String {
        case yes = "YES"
        case no = "NO"
    }

    /// UIテストで初期表示する画面を指定する起動引数
    enum InitialViewOption: String {
        case setTimerView
        case settingsView
        case countdownView
        case timerCompletionView
    }

    /// その他のUIテスト用起動引数 (現在は空)
    enum LaunchArguments: String {
        // 例: case enableDebugMenu = "-enable-debug-menu"
        // 将来的に必要であればここに追加
    }
}
