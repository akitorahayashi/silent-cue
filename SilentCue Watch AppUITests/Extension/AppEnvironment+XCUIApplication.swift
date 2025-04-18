import XCTest

// SCAppEnvironment の拡張として、UIテストでの環境変数/引数設定メソッドを定義
extension SCAppEnvironment {
    private static func setEnv(_ key: EnvKeys, to value: EnvValues, for app: XCUIApplication) {
        app.launchEnvironment[key.rawValue] = value.rawValue
    }

    static func setMultipleEnv(_ values: [EnvKeys: EnvValues], for app: XCUIApplication) {
        for (key, value) in values {
            app.launchEnvironment[key.rawValue] = value.rawValue
        }
    }

    /// 指定された起動引数でテスト環境をセットアップする
    static func setupEnvironment(for app: XCUIApplication, launchArgument: LaunchArguments? = nil) {
        setEnv(.disableNotificationsForTesting, to: .yes, for: app) // 共通の環境変数
        app.launchArguments = launchArgument != nil ? [launchArgument!.rawValue] : []
    }

    // --- 以前の個別のテスト環境設定メソッドは削除済み ---

    // setupStandardTestEnvironment は削除
    // static func setupStandardTestEnvironment(for app: XCUIApplication) {
    //     self.setEnv(.disableNotificationsForTesting, to: .yes, for: app)
    // }
}
