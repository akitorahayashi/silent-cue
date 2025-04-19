import WatchKit // For WKHapticType

/// 触覚フィードバック機能のインターフェース
protocol HapticsServiceProtocol {
    /// 指定されたタイプの触覚フィードバックを再生します。
    /// - Parameter type: 再生する触覚フィードバックのタイプ (`WKHapticType`)。
    func play(_ type: WKHapticType) async
    // 将来的に他のメソッドが必要な場合（例：stop()）はここに追加
}
