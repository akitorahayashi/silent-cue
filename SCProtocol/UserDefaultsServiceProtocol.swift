import SCShared

public protocol UserDefaultsServiceProtocol {
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys)
    func object(forKey defaultName: UserDefaultsKeys) -> Any?
    func remove(forKey defaultName: UserDefaultsKeys)
    func removeAll()
    func saveHapticFeedbackType(_ type: HapticFeedbackType)
    func loadHapticFeedbackType() -> HapticFeedbackType
}
