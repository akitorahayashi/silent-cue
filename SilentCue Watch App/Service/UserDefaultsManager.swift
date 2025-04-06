import Foundation

/// UserDefaultsへのアクセスを管理するシングルトンクラス
final class UserDefaultsManager {
    // UserDefaultsのキーを管理する列挙型
    enum Key: String, CaseIterable {
        case stopVibrationAutomatically
        case hapticType
        case appTheme // アプリのテーマ設定（light/dark）
    }
    
    // シングルトンインスタンス
    static let shared = UserDefaultsManager()
    private init() {}
    
    // 実際のUserDefaultsインスタンス
    private let defaults = UserDefaults.standard
    
    // MARK: - 汎用的な操作
    
    /// 値の保存（任意のオブジェクト型）
    func set(_ value: Any, forKey key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    /// オブジェクトの取得
    func object(forKey key: Key) -> Any? {
        return defaults.object(forKey: key.rawValue)
    }
    
    /// 値の削除
    func remove(forKey key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }
    
    /// 全ての値をリセット
    func removeAll() {
        Key.allCases.forEach { key in
            defaults.removeObject(forKey: key.rawValue)
        }
    }
} 