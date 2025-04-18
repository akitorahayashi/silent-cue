import Foundation

// @testable import SilentCue_Watch_App // アプリ本体のモジュールをインポート <- Remove this line

// MARK: - UserDefaults Keys (Copied for Test Target)

/// UserDefaultsのキーを管理する列挙型
enum SCUserDefaultsKeys: String, CaseIterable {
    case hapticType
    case isFirstLaunch
}

// MARK: - UserDefaults Protocol (Copied for Test Target)

/// UserDefaultsへのアクセスを管理するプロトコル
protocol SCUserDefaultsManagerProtocol {
    /// 値の保存（任意のオブジェクト型）
    func set(_ value: Any?, forKey defaultName: SCUserDefaultsKeys)

    /// オブジェクトの取得
    func object(forKey defaultName: SCUserDefaultsKeys) -> Any?

    /// 値の削除
    func remove(forKey defaultName: SCUserDefaultsKeys)

    /// UserDefaultsKeys に定義された全ての値を削除
    func removeAll()
}

/// SCUserDefaultsManagerのモック実装
class MockUserDefaultsManager: SCUserDefaultsManagerProtocol {
    private var storage: [String: Any] = [:] // UserDefaultsの代わりとなるインメモリ辞書

    func set(_ value: Any?, forKey defaultName: SCUserDefaultsKeys) {
        if let value {
            storage[defaultName.rawValue] = value
        } else {
            storage.removeValue(forKey: defaultName.rawValue) // nilがセットされたら削除
        }
    }

    func object(forKey defaultName: SCUserDefaultsKeys) -> Any? {
        storage[defaultName.rawValue]
    }

    func remove(forKey defaultName: SCUserDefaultsKeys) {
        storage.removeValue(forKey: defaultName.rawValue)
    }

    /// モックのストレージを全てクリアする
    func removeAll() {
        storage.removeAll()
    }

    // --- Mock Specific Methods ---

    /// 現在のストレージの内容を取得する（テスト用）
    func getAllValues() -> [String: Any] {
        storage
    }
}
