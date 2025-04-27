import Foundation

/// アプリケーションの実行環境を管理する構造体
public enum SCAppEnvironment {
    /// UIテストまたは特定のデバッグシナリオで使用される起動引数
    public enum LaunchArguments: String {
        /// UIテストモードでアプリを起動することを示す
        case uiTesting
    }

    /// UIテストで初期表示する画面を指定する
    public enum InitialViewOption: String {
        case setTimerView
        case settingsView
        case countdownView
        case timerCompletionView
    }
}
