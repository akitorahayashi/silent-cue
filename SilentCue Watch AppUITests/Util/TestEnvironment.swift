import XCTest

enum TestEnvironment {
    enum EnvKeys: String {
        case disableNotifications = "DISABLE_NOTIFICATIONS_FOR_TESTING"

        static var allKeys: [EnvKeys] {
            [.disableNotifications]
        }
    }

    enum EnvValues: String {
        case yes = "YES"
        case no = "NO"
    }

    static func set(_ key: EnvKeys, to value: EnvValues, for app: XCUIApplication) {
        app.launchEnvironment[key.rawValue] = value.rawValue
    }

    static func setMultiple(_ values: [EnvKeys: EnvValues], for app: XCUIApplication) {
        for (key, value) in values {
            app.launchEnvironment[key.rawValue] = value.rawValue
        }
    }

    static func setupStandardTestEnvironment(for app: XCUIApplication) {
        set(.disableNotifications, to: .yes, for: app)
    }

    static func clearAll(for app: XCUIApplication) {
        for key in EnvKeys.allKeys {
            app.launchEnvironment.removeValue(forKey: key.rawValue)
        }
    }
}
