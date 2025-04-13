import ComposableArchitecture
import Foundation

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

    // テスト用の値もここで定義できる
    static var testValue: UserDefaultsManagerProtocol = UserDefaultsManager.shared
}

// 既存の依存性は互換性のために残しておく
extension DependencyValues {
    var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}

struct UserDefaultsClient {
    var setBool: @Sendable (Bool, String) -> Void
    var bool: @Sendable (String) -> Bool

    var setString: @Sendable (String, String) -> Void
    var string: @Sendable (String) -> String?
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        setBool: { UserDefaults.standard.set($0, forKey: $1) },
        bool: { UserDefaults.standard.bool(forKey: $0) },
        setString: { UserDefaults.standard.set($0, forKey: $1) },
        string: { UserDefaults.standard.string(forKey: $0) }
    )
}
