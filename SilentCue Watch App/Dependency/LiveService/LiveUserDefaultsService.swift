import ComposableArchitecture
import Foundation
import XCTestDynamicOverlay

final class LiveUserDefaultsService: UserDefaultsServiceProtocol {
    private let defaults = UserDefaults.standard

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

extension LiveUserDefaultsService: TestDependencyKey {
    static let testValue: UserDefaultsServiceProtocol = {
        struct UnimplementedUserDefaultsService: UserDefaultsServiceProtocol {
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
