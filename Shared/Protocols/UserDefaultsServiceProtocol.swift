/// UserDefaultsのキーを管理する列挙型
public enum UserDefaultsKeys: String, CaseIterable {
    case hapticType
    case isFirstLaunch
}

/// UserDefaultsへのアクセスを管理するインターフェース
public protocol UserDefaultsServiceProtocol { // Rename protocol
    /// 値の保存（任意のオブジェクト型）
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys)

    /// オブジェクトの取得
    func object(forKey defaultName: UserDefaultsKeys) -> Any?

    /// 値の削除
    func remove(forKey defaultName: UserDefaultsKeys)

    /// UserDefaultsKeys に定義された全ての値を削除
    func removeAll()
}
