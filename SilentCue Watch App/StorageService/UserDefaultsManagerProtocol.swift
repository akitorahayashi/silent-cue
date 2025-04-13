import Foundation

/// UserDefaultsのキーを管理する列挙型
enum UserDefaultsKeys: String, CaseIterable {
    case stopVibrationAutomatically
    case hapticType
}

/// UserDefaultsへのアクセスを管理するプロトコル
protocol UserDefaultsManagerProtocol {
    /// 値の保存（任意のオブジェクト型）
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys)

    /// オブジェクトの取得
    func object(forKey defaultName: UserDefaultsKeys) -> Any?

    /// 値の削除
    func remove(forKey defaultName: UserDefaultsKeys)
}
