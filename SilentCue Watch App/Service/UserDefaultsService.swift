import ComposableArchitecture
import Foundation
import XCTestDynamicOverlay

// MARK: - UserDefaults サービス実装

final class LiveUserDefaultsService: UserDefaultsServiceProtocol { // クラス名を変更、新しいプロトコルに準拠
    private let defaults = UserDefaults.standard

    // MARK: - プロトコルメソッド

    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        defaults.set(value, forKey: defaultName.rawValue)
    }

    func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        defaults.object(forKey: defaultName.rawValue)
    }

    func remove(forKey defaultName: UserDefaultsKeys) {
        defaults.removeObject(forKey: defaultName.rawValue)
    }

    func removeAll() {
        for key in UserDefaultsKeys.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
    }
}

// MARK: - TCA 依存関係

extension DependencyValues {
    var userDefaultsService: UserDefaultsServiceProtocol { // プロパティ名を変更、型とキーを更新
        get { self[UserDefaultsServiceKey.self] }
        set { self[UserDefaultsServiceKey.self] = newValue }
    }
}

private enum UserDefaultsServiceKey: DependencyKey { // キーenum名を変更
    static let liveValue: UserDefaultsServiceProtocol = LiveUserDefaultsService() // 新しいクラスとプロトコルを使用

    // プレビューには MockUserDefaultsManager を使用します (必要に応じて新しいプロトコルに準拠することを確認)
    // MockUserDefaultsManager が UserDefaultsServiceProtocol に準拠できるか、適合できると仮定します
    static let previewValue: UserDefaultsServiceProtocol = MockUserDefaultsManager()
}

extension LiveUserDefaultsService: TestDependencyKey { // 拡張ターゲットを更新
    static let testValue: UserDefaultsServiceProtocol = { // プロトコル型を更新
        struct UnimplementedUserDefaultsService: UserDefaultsServiceProtocol { // 構造体名を変更、新しいプロトコルに準拠
            func set(_: Any?, forKey _: UserDefaultsKeys) {
                XCTFail("\(Self.self).set は未実装です")
            }

            func object(forKey _: UserDefaultsKeys) -> Any? {
                XCTFail("\(Self.self).object は未実装です")
                return nil
            }

            func remove(forKey _: UserDefaultsKeys) {
                XCTFail("\(Self.self).remove は未実装です")
            }

            func removeAll() {
                XCTFail("\(Self.self).removeAll は未実装です")
            }
        }
        return UnimplementedUserDefaultsService()
    }()
}
