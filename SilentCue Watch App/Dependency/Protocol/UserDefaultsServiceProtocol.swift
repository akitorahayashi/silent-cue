enum UserDefaultsKeys: String, CaseIterable {
    case hapticType
    case isFirstLaunch
}

protocol UserDefaultsServiceProtocol {
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys)
    func object(forKey defaultName: UserDefaultsKeys) -> Any?
    func remove(forKey defaultName: UserDefaultsKeys)
    func removeAll()
}
