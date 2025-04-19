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
        otherArguments: [SCAppEnvironment.LaunchArguments] = []
    ) {
        var arguments: [String] = [LaunchArguments.uiTesting.rawValue]
        if let initialViewRawValue = initialView?.rawValue {
            arguments.append(initialViewRawValue)
        }
        arguments.append(contentsOf: otherArguments.map(\.rawValue))

        app.launchArguments = arguments
    }
}
