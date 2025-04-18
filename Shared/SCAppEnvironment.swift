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

    /// UIテストなどで使用する起動引数
    enum LaunchArguments: String {
        /// TimerCompletionView を直接表示する
        case testingTimerCompletionView = "-testing-timer-completion-view"
    }
}
