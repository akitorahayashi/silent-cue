import SCShared
@testable import SilentCue_Watch_App
import XCTest

extension SCAppEnvironment {
    private static func setEnv(_ key: LaunchArguments, to value: String, for app: XCUIApplication) {
        app.launchEnvironment[key.rawValue] = value
    }

    static func setMultipleEnv(_ values: [LaunchArguments: String], for app: XCUIApplication) {
        for (key, value) in values {
            setEnv(key, to: value, for: app)
        }
    }

    /// 指定された初期画面と追加引数でUIテスト環境をセットアップする
    static func setupUITestEnv(
        for app: XCUIApplication,
        initialView: InitialViewOption? = nil,
        notificationAuthorized: Bool? = nil
    ) {
        var arguments: [String] = [LaunchArguments.uiTesting.rawValue]
        if let initialViewRawValue = initialView?.rawValue {
            arguments.append(initialViewRawValue)
        }

        app.launchArguments = arguments

        var environment: [String: String] = [:]
        if let isAuthorized = notificationAuthorized {
            environment[LaunchEnvironmentKeys.uiTestNotificationAuthorized.rawValue] = isAuthorized ? "TRUE" : "FALSE"
        }
        app.launchEnvironment = environment
    }
}
