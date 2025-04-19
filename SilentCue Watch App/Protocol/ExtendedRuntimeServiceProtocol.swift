import Foundation

/// 拡張ランタイムセッション管理機能のインターフェース
protocol ExtendedRuntimeServiceProtocol {
    func startSession(duration: TimeInterval, targetEndTime: Date?, completionHandler: (() -> Void)?)
    func stopSession()
    func checkAndClearBackgroundCompletionFlag() -> Bool
}
