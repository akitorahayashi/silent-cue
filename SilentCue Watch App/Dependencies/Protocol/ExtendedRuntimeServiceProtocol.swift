import Foundation

protocol ExtendedRuntimeServiceProtocol {
    /// セッション完了イベントを通知する非同期ストリーム
    var completionEvents: AsyncStream<Void> { get }

    /// 拡張ランタイムセッションを開始する。
    /// - Parameters:
    ///   - duration: セッションの最大持続時間（秒単位）
    ///   - targetEndTime: タイマーの実際の目標終了時刻（通知スケジュールなどに使用）
    func startSession(duration: TimeInterval, targetEndTime: Date?)

    /// 拡張ランタイムセッションを停止する。
    func stopSession()
}
