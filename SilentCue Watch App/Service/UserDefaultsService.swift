import ComposableArchitecture
import Foundation
import XCTestDynamicOverlay

// MARK: - UserDefaults Service Implementation

final class LiveUserDefaultsService: UserDefaultsServiceProtocol { // Rename class, conform to new protocol
    private let defaults = UserDefaults.standard

    // MARK: - Protocol Methods

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

    // TCAのための public init
    public init() {}
}

// MARK: - TCA Dependency

extension DependencyValues {
    var userDefaultsService: UserDefaultsServiceProtocol { // Rename property, update type and key
        get { self[UserDefaultsServiceKey.self] }
        set { self[UserDefaultsServiceKey.self] = newValue }
    }
}

private enum UserDefaultsServiceKey: DependencyKey { // Rename key enum
    static let liveValue: UserDefaultsServiceProtocol = LiveUserDefaultsService() // Use new class and protocol

    // Use MockUserDefaultsManager for previews (ensure it conforms to new protocol if necessary)
    // Assuming MockUserDefaultsManager can conform or be adapted to UserDefaultsServiceProtocol
    static let previewValue: UserDefaultsServiceProtocol = MockUserDefaultsManager()
}

extension LiveUserDefaultsService: TestDependencyKey { // Update extension target
    static let testValue: UserDefaultsServiceProtocol = { // Update protocol type
        struct UnimplementedUserDefaultsService: UserDefaultsServiceProtocol { // Rename struct, conform to new protocol
            func set(_: Any?, forKey _: UserDefaultsKeys) {
                XCTFail("\(Self.self).set is unimplemented")
            }

            func object(forKey _: UserDefaultsKeys) -> Any? {
                XCTFail("\(Self.self).object is unimplemented")
                return nil
            }

            func remove(forKey _: UserDefaultsKeys) {
                XCTFail("\(Self.self).remove is unimplemented")
            }

            func removeAll() {
                XCTFail("\(Self.self).removeAll is unimplemented")
            }
        }
        return UnimplementedUserDefaultsService()
    }()
}
