import Foundation
@testable import SilentCue_Watch_App

/// テスト用のUserDefaultsManagerモック
final class MockUserDefaultsManager: UserDefaultsManagerProtocol {
    // 値を保存するための内部ストレージ
    var storage: [UserDefaultsKeys: Any?] = [:]

    // 特定のキーに対応する値を返す
    func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        storage[defaultName] ?? nil
    }

    // 特定のキーに値を設定する
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        storage[defaultName] = value
    }

    // 特定のキーの値を削除する
    func remove(forKey defaultName: UserDefaultsKeys) {
        storage.removeValue(forKey: defaultName)
    }

    // すべての値を削除する
    func removeAll() {
        storage.removeAll()
    }

    // テストのために初期値を設定するヘルパー (任意)
    func setupInitialValues(_ values: [UserDefaultsKeys: Any?]) {
        storage = values
    }
}
