import XCTest

/// 共通のUI Testing定数を定義する列挙型
enum UITestConstants {
    /// スクロール/スワイプの速度関連の定数
    enum ScrollVelocity {
        static let standard: XCUIGestureVelocity = 150
        static let slow: XCUIGestureVelocity = 100
        static let fast: XCUIGestureVelocity = 300
    }

    /// タイムアウト関連の定数
    enum Timeout {
        static let standard: TimeInterval = 5
        static let short: TimeInterval = 3
    }
}
