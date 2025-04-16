import Foundation

/// アプリが使用する環境変数定数
enum AppEnvironmentConstants {
    /// 環境変数キー
    enum EnvKeys {
        /// テスト中に通知を無効化するキー
        static let disableNotifications = "DISABLE_NOTIFICATIONS_FOR_TESTING"
    }
    
    /// 環境変数値
    enum EnvValues {
        static let yes = "YES"
        static let no = "NO"
    }
} 
