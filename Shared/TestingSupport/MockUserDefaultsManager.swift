import Foundation
@testable import SilentCue_Watch_App // For UserDefaultsKeys

/// `UserDefaultsServiceProtocol` のモック実装。
/// テスト中にUserDefaultsの動作を制御するために使用します。
final class MockUserDefaultsManager: UserDefaultsServiceProtocol { // Conform to the new protocol
    /// UserDefaultsの代わりとなるインメモリ辞書。
    private var storage: [String: Any] = [:]

    /// モックインスタンスを初期化します。
    public init() {}

    /// 指定されたキーに値を設定します（モック用）。
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        if let value {
            storage[defaultName.rawValue] = value
        } else {
            storage.removeValue(forKey: defaultName.rawValue)
        }
    }

    /// 指定されたキーに関連付けられたオブジェクトを返します（モック用）。
    func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        storage[defaultName.rawValue]
    }

    /// 指定されたキーの値を削除します（モック用）。
    func remove(forKey defaultName: UserDefaultsKeys) {
        storage.removeValue(forKey: defaultName.rawValue)
    }

    /// モックストレージからすべての値を削除します。
    func removeAll() {
        storage.removeAll()
    }

    // --- Mock Specific Methods ---

    /// 現在のストレージの内容を返します（テスト検証用）。
    func getAllValues() -> [String: Any] {
        storage
    }
}
