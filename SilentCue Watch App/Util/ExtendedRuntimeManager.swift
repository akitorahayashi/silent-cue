import Foundation
import WatchKit

/// バックグラウンド実行をサポートする拡張ランタイムセッション管理クラス
class ExtendedRuntimeManager: NSObject, WKExtendedRuntimeSessionDelegate {
    /// シングルトンインスタンス
    static let shared = ExtendedRuntimeManager()
    
    /// 現在のセッション
    private var session: WKExtendedRuntimeSession?
    
    /// 拡張ランタイムセッションを開始する
    /// - Parameter duration: 予想される実行時間（秒）
    func startSession(duration: TimeInterval) {
        // 既存のセッションを終了
        stopSession()
        
        // 新しいセッションを開始
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        self.session = session
        
        print("Extended runtime session started")
    }
    
    /// 拡張ランタイムセッションを停止する
    func stopSession() {
        session?.invalidate()
        session = nil
        print("Extended runtime session stopped")
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Extended runtime session invalidated with reason: \(reason)")
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session did start")
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session will expire")
    }
} 