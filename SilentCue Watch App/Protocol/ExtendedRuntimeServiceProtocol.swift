import Foundation

/// 拡張ランタイムセッション管理機能のインターフェース
protocol ExtendedRuntimeServiceProtocol {
    /// セッションの完了イベントを通知するストリーム
    var completionEvents: AsyncStream<Void> { get }

    /// セッションを開始します。
    /// - Parameters:
    ///   - duration: セッションの最大期間（システムが保証するものではない）
    ///   - targetEndTime: タイマーの目標終了時刻 (バックグラウンド更新のため)
    func startSession(duration: TimeInterval, targetEndTime: Date?)

    /// 現在のセッションを停止します。
    func stopSession()

    // This flag seems less relevant with the stream approach, consider removing later.
    func checkAndClearBackgroundCompletionFlag() -> Bool
}
