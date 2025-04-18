import Foundation

/// アプリケーションの環境設定や起動引数を管理する名前空間
enum SCAppEnvironment {
    /// UIテストまたは特定のデバッグシナリオで使用される起動引数
    enum LaunchArguments: String {
        /// UIテストモードでアプリを起動することを示す
        case uiTesting
    }

    /// UIテストで初期表示する画面を指定する
    enum InitialViewOption: String {
        case setTimerView
        case settingsView
        case countdownView
        case timerCompletionView
    }
}
