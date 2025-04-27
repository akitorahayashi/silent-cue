import Combine
import Foundation
import SCProtocol
import SCShared
import Dependencies

public class MockUserDefaultsManager: UserDefaultsServiceProtocol {
    /// UserDefaultsの代わりとなるインメモリ辞書
    public var storage: [String: Any] = [
        UserDefaultsKeys.hapticType.rawValue: HapticFeedbackType.success.rawValue, // Use enum rawValue
        UserDefaultsKeys.isFirstLaunch.rawValue: true // Add default for isFirstLaunch
    ]
    
    // 検証用の呼び出し追跡
    public var saveHapticTypeCallCount = 0
    public var loadHapticTypeCallCount = 0
    public var setCallCount = 0
    public var objectCallCount = 0
    public var boolCallCount = 0
    public var removeCallCount = 0
    public var removeAllCallCount = 0

    public init() {}

    public func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        setCallCount += 1
        let key = defaultName.rawValue
        if let value {
            storage[key] = value
            print("MockUserDefaultsManager: Set \(key) = \(value)")
        } else {
            storage.removeValue(forKey: key)
            print("MockUserDefaultsManager: Removed value for \(key)")
        }
    }

    public func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        objectCallCount += 1
        let key = defaultName.rawValue
        let value = storage[key]
        print("MockUserDefaultsManager: Got object for \(key): \(value ?? "nil")")
        return value
    }

    public func bool(forKey defaultName: UserDefaultsKeys) -> Bool? {
        boolCallCount += 1
        let key = defaultName.rawValue
        let value = storage[key] as? Bool
        print("MockUserDefaultsManager: Got bool for \(key): \(value.map { String(describing: $0) } ?? "nil")")
        return value
    }

    public func remove(forKey defaultName: UserDefaultsKeys) {
        removeCallCount += 1
        let key = defaultName.rawValue
        storage.removeValue(forKey: key)
        print("MockUserDefaultsManager: Removed key \(key)")
    }

    public func removeAll() {
        removeAllCallCount += 1
        storage.removeAll()
        print("MockUserDefaultsManager: Removed all keys")
    }

    // --- プロトコルメソッド ---

    public func saveHapticFeedbackType(_ type: HapticFeedbackType) {
        saveHapticTypeCallCount += 1
        let key = UserDefaultsKeys.hapticType.rawValue
        storage[key] = type.rawValue
        print("MockUserDefaultsManager: Saved haptic type: \(type.rawValue)")
    }

    public func loadHapticFeedbackType() -> HapticFeedbackType {
        loadHapticTypeCallCount += 1
        let key = UserDefaultsKeys.hapticType.rawValue
        let value = storage[key] as? String ?? HapticFeedbackType.success.rawValue
        let type = HapticFeedbackType(rawValue: value) ?? .success
        print("MockUserDefaultsManager: Loaded haptic type: \(type.rawValue)")
        return type
    }

    // --- モック固有のメソッド ---
    public func getAllValues() -> [String: Any] {
        storage
    }

    // テスト用のリセット関数
    public func reset() {
        storage = [
            UserDefaultsKeys.hapticType.rawValue: HapticFeedbackType.success.rawValue,
            UserDefaultsKeys.isFirstLaunch.rawValue: true
        ]
        saveHapticTypeCallCount = 0
        loadHapticTypeCallCount = 0
        setCallCount = 0
        objectCallCount = 0
        boolCallCount = 0
        removeCallCount = 0
        removeAllCallCount = 0
        print("MockUserDefaultsManager: Reset storage to defaults.")
    }
}
