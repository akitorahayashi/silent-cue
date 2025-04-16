import ComposableArchitecture // TCA Dependencyのため追加
import Foundation

// MARK: - UserDefaults Keys

/// UserDefaultsのキーを管理する列挙型
enum UserDefaultsKeys: String, CaseIterable {
    case hapticType
    case isFirstLaunch
}

// MARK: - UserDefaults Protocol

/// UserDefaultsへのアクセスを管理するプロトコル
protocol UserDefaultsManagerProtocol {
    /// 値の保存（任意のオブジェクト型）
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys)

    /// オブジェクトの取得
    func object(forKey defaultName: UserDefaultsKeys) -> Any?

    /// 値の削除
    func remove(forKey defaultName: UserDefaultsKeys)

    /// UserDefaultsKeys に定義された全ての値を削除
    func removeAll()
}

// MARK: - UserDefaults Manager Implementation

/// UserDefaultsへのアクセスを管理するシングルトンクラス
final class UserDefaultsManager: UserDefaultsManagerProtocol {
    // シングルトンインスタンス
    static let shared = UserDefaultsManager()
    private init() {}

    private let defaults = UserDefaults.standard

    // MARK: - Protocol Methods

    /// 値の保存（任意のオブジェクト型）
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        defaults.set(value, forKey: defaultName.rawValue)
    }

    /// オブジェクトの取得
    func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        defaults.object(forKey: defaultName.rawValue)
    }

    /// 値の削除
    func remove(forKey defaultName: UserDefaultsKeys) {
        defaults.removeObject(forKey: defaultName.rawValue)
    }

    /// 全ての値をリセット
    func removeAll() {
        for key in UserDefaultsKeys.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
    }
}

// MARK: - TCA Dependency

// TCAの依存性としてUserDefaultsManagerを登録
extension DependencyValues {
    var userDefaultsManager: UserDefaultsManagerProtocol {
        get { self[UserDefaultsManagerKey.self] }
        set { self[UserDefaultsManagerKey.self] = newValue }
    }
}

// UserDefaultsManagerのための依存性キーの定義
private enum UserDefaultsManagerKey: DependencyKey {
    static let liveValue: UserDefaultsManagerProtocol = UserDefaultsManager.shared

    // テスト時にはモック実装などを提供できるように `testValue` も用意することが一般的
    // static var testValue: UserDefaultsManagerProtocol = MockUserDefaultsManager() // 例
    static var testValue: UserDefaultsManagerProtocol = UserDefaultsManager.shared // 現状はliveと同じ
}
