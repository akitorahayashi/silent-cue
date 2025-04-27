import SCShared

public protocol UserDefaultsServiceProtocol {
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys)
    func object(forKey defaultName: UserDefaultsKeys) -> Any?
    func remove(forKey defaultName: UserDefaultsKeys)
    func removeAll()
    func saveHapticType(_ type: HapticType)
    func loadHapticType() -> HapticType
}
