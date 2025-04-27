import ComposableArchitecture
import Foundation
import SCProtocol
import SCShared

public class LiveUserDefaultsService: UserDefaultsServiceProtocol {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func saveHapticFeedbackType(_ type: HapticFeedbackType) {
        userDefaults.set(type.rawValue, forKey: "hapticType")
    }

    public func loadHapticFeedbackType() -> HapticFeedbackType {
        let savedValue = userDefaults.string(forKey: "hapticType") ?? HapticFeedbackType.success.rawValue
        return HapticFeedbackType(rawValue: savedValue) ?? .success
    }

    public func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        userDefaults.set(value, forKey: defaultName.rawValue)
    }

    public func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        userDefaults.object(forKey: defaultName.rawValue)
    }

    public func remove(forKey defaultName: UserDefaultsKeys) {
        userDefaults.removeObject(forKey: defaultName.rawValue)
    }

    public func removeAll() {
        for key in UserDefaultsKeys.allCases {
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }
}
