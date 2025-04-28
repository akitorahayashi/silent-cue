import Foundation

/// アプリケーションの実行環境を管理する構造体
public enum SCAppEnvironment {
    /// UIテストまたは特定のデバッグシナリオで使用される起動引数
    public enum LaunchArguments: String {
        /// UIテストモードでアプリを起動することを示す
        case uiTesting
        /// UIテスト時に通知許可状態をシミュレートする ("TRUE" or "FALSE")
        case uiTestNotificationAuthorized
    }

    /// UIテスト環境変数キー
    public enum LaunchEnvironmentKeys: String {
        case uiTestNotificationAuthorized
    }

    /// UIテストで初期表示する画面を指定する
    public enum InitialViewOption: String {
        case setTimerView
        case settingsView
        case countdownView
        case timerCompletionView
    }
}
