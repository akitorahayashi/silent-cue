import XCTest

/// 共通のUI Testing定数を定義する列挙型
enum UITestConstants {
    /// スクロール/スワイプの速度関連の定数
    enum ScrollVelocity {
        /// スクロール/スワイプの標準速度
        static let standard: XCUIGestureVelocity = 150

        /// 低速スクロール/スワイプの速度
        static let slow: XCUIGestureVelocity = 100

        /// 高速スクロール/スワイプの速度
        static let fast: XCUIGestureVelocity = 300
    }

    /// タイムアウト関連の定数
    enum Timeout {
        /// UI要素を待機する標準タイムアウト (秒)
        static let standard: TimeInterval = 5

        /// UI要素を待機する短いタイムアウト (秒)
        static let short: TimeInterval = 3
    }
}
