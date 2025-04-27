import Combine
import Foundation
@testable import SilentCue_Watch_App

final class MockUserDefaultsManager: UserDefaultsServiceProtocol {
    /// UserDefaultsの代わりとなるインメモリ辞書
    private var storage: [String: Any] = [:]

    public init() {}

    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        if let value {
            storage[defaultName.rawValue] = value
        } else {
            storage.removeValue(forKey: defaultName.rawValue)
        }
    }

    func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        storage[defaultName.rawValue]
    }

    func remove(forKey defaultName: UserDefaultsKeys) {
        storage.removeValue(forKey: defaultName.rawValue)
    }

    func removeAll() {
        storage.removeAll()
    }

    // --- Mock Specific Methods ---
    func getAllValues() -> [String: Any] {
        storage
    }
}
