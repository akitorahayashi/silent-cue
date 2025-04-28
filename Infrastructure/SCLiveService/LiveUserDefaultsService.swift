import ComposableArchitecture
import Foundation
import SCProtocol
import SCShared

public class LiveUserDefaultsService: UserDefaultsServiceProtocol {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func saveHapticType(_ type: HapticType) {
        userDefaults.set(type.rawValue, forKey: "hapticType")
    }

    public func loadHapticType() -> HapticType {
        let savedValue = userDefaults.string(forKey: "hapticType") ?? HapticType.standard.rawValue
        return HapticType(rawValue: savedValue) ?? .standard
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
