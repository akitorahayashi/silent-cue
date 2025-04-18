import XCTest

// AppEnvironment の拡張として、UIテストでの環境変数設定メソッドを定義
extension AppEnvironment {
    static func set(_ key: EnvKeys, to value: EnvValues, for app: XCUIApplication) {
        app.launchEnvironment[key.rawValue] = value.rawValue
    }

    static func setMultiple(_ values: [EnvKeys: EnvValues], for app: XCUIApplication) {
        for (key, value) in values {
            app.launchEnvironment[key.rawValue] = value.rawValue
        }
    }

    static func setupStandardTestEnvironment(for app: XCUIApplication) {
        self.set(.disableNotificationsForTesting, to: .yes, for: app)
    }
} 
