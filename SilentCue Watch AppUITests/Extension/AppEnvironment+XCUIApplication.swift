import XCTest

extension SCAppEnvironment {
    private static func setEnv(_ key: LaunchArguments, to value: String, for app: XCUIApplication) {
        guard key == .disableNotificationsForTesting else {
            print("Warning: Trying to set non-env key \(key.rawValue) as environment variable.")
            return
        }
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
        otherArguments: [SCAppEnvironment.LaunchArguments] = []
    ) {
        // UITest環境では通知を無効化
        setEnv(.disableNotificationsForTesting, to: "YES", for: app)

        var arguments: [String] = [LaunchArguments.uiTesting.rawValue]
        if let initialViewRawValue = initialView?.rawValue {
            arguments.append(initialViewRawValue)
        }
        arguments.append(contentsOf: otherArguments.map(\.rawValue))

        app.launchArguments = arguments
    }
}
