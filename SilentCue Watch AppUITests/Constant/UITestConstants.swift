import XCTest

/// 共通のUI Testing定数を定義する列挙型
enum UITestConstants {
    static let scrollVelocity: XCUIGestureVelocity = 200

    /// タイムアウト関連の定数
    enum Timeout {
        static let standard: TimeInterval = 5
        static let short: TimeInterval = 3
    }
}
