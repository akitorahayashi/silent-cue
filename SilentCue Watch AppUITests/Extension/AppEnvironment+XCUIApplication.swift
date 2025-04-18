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

    // --- 個別のテスト環境を設定し、アプリを起動する ---

    /// SetTimerView テスト用の設定と起動
    static func setupEnvAndLaunchForSetTimerViewTest(for app: XCUIApplication) {
        self.setEnv(.disableNotificationsForTesting, to: .yes, for: app)
        app.launchArguments = [] // 引数なし
        app.launch()
        NotificationPermissionHelper.ensureNotificationPermission(for: app)
    }

    /// SettingsView テスト用の設定と起動
    static func setupEnvAndLaunchForSettingsViewTest(for app: XCUIApplication) {
        self.setEnv(.disableNotificationsForTesting, to: .yes, for: app)
        app.launchArguments = [] // 引数なし
        app.launch()
        NotificationPermissionHelper.ensureNotificationPermission(for: app)
    }

    /// CountdownView テスト用の設定と起動
    static func setupEnvAndLaunchForCountdownViewTest(for app: XCUIApplication) {
        self.setEnv(.disableNotificationsForTesting, to: .yes, for: app)
        app.launchArguments = [] // 引数なし
        app.launch()
        NotificationPermissionHelper.ensureNotificationPermission(for: app)
    }

    /// TimerCompletionView テスト用の設定と起動
    static func setupEnvAndLaunchForTimerCompletionViewTest(for app: XCUIApplication) {
        self.setEnv(.disableNotificationsForTesting, to: .yes, for: app)
        // 固有の起動引数を設定
        app.launchArguments = [LaunchArguments.testingTimerCompletionView.rawValue]
        app.launch()
    }

    // setupStandardTestEnvironment は削除
    // static func setupStandardTestEnvironment(for app: XCUIApplication) {
    //     self.setEnv(.disableNotificationsForTesting, to: .yes, for: app)
    // }
} 
