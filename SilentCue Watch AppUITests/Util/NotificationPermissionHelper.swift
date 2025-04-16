import XCTest

enum NotificationPermissionHelper {
    /// 通知許可のダイアログを処理する関数
    static func ensureNotificationPermission(for app: XCUIApplication) {
        let velocity = UITestConstants.ScrollVelocity.standard

        // まだ認証していない
        let notificationNotAuthorizedAlertTitle = app.staticTexts["通知について"]
        // 1. アプリ内の通知説明アラート
        if notificationNotAuthorizedAlertTitle.waitForExistence(timeout: UITestConstants.Timeout.short) {
            // スクロールして「許可する」ボタンを表示
            app.swipeUp(velocity: velocity)
            let allowButton = app.buttons["許可する"]

            // 「許可する」ボタンをタップ
            allowButton.tap()

            // 2. システムの通知許可ダイアログを処理
            sleep(2) // システムダイアログが表示されるまで少し待機

            // Watch OSのCarouselアプリ（システムUI）が表示するアラート
            let carousel = XCUIApplication(bundleIdentifier: "com.apple.Carousel")

            // スクロールして「許可」ボタンを表示
            app.swipeUp(velocity: velocity)
            // "許可" ボタンを探す
            let carouselAllowButton = carousel.buttons["許可"]
            if carouselAllowButton.waitForExistence(timeout: UITestConstants.Timeout.standard) {
                carouselAllowButton.tap()
            }
        }
    }
}
