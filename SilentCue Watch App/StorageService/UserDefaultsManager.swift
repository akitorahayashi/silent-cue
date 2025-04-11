import Foundation

/// UserDefaultsへのアクセスを管理するシングルトンクラス
final class UserDefaultsManager: UserDefaultsManagerProtocol {
    // シングルトンインスタンス
    static let shared = UserDefaultsManager()
    private init() {}
    
    // 実際のUserDefaultsインスタンス
    private let defaults = UserDefaults.standard
    
    // MARK: - 汎用的な操作
    
    /// 値の保存（任意のオブジェクト型）
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        defaults.set(value, forKey: defaultName.rawValue)
    }
    
    /// オブジェクトの取得
    func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        return defaults.object(forKey: defaultName.rawValue)
    }
    
    /// 値の削除
    func remove(forKey defaultName: UserDefaultsKeys) {
        defaults.removeObject(forKey: defaultName.rawValue)
    }
    
    /// 全ての値をリセット
    func removeAll() {
        UserDefaultsKeys.allCases.forEach { key in
            defaults.removeObject(forKey: key.rawValue)
        }
    }
} 