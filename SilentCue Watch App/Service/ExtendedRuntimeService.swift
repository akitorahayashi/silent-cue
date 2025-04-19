import ComposableArchitecture
import Foundation
import WatchKit
import XCTestDynamicOverlay

/// バックグラウンド実行をサポートする拡張ランタイムセッション管理クラス (ライブ実装)
final class LiveExtendedRuntimeService: NSObject, WKExtendedRuntimeSessionDelegate, ExtendedRuntimeServiceProtocol {
    // MARK: - Completion Stream

    private var completionContinuation: AsyncStream<Void>.Continuation?
    private(set) lazy var completionEvents: AsyncStream<Void> = AsyncStream { continuation in
        self.completionContinuation = continuation
    }

    /// 現在のセッション
    private var session: WKExtendedRuntimeSession?

    /// 拡張ランタイムセッションを開始する (シグネチャ変更)
    func startSession(duration _: TimeInterval, targetEndTime _: Date? = nil) { // completionHandler 削除済
        stopSession() // Ensures any previous session and continuation are cleaned up

        // 新しいセッションを開始
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        // self.session は extendedRuntimeSessionDidStart で設定される

        print("拡張ランタイムセッションの開始を要求しました")
    }

    /// 拡張ランタイムセッションを停止する
    func stopSession() {
        session?.invalidate()
        session = nil

        // Continuation を終了させる
        completionContinuation?.finish()
        completionContinuation = nil

        print("拡張ランタイムセッションが停止されました")
    }

    /// アプリがフォアグラウンドに戻ったときに呼び出して、バックグラウンドでタイマーが完了していたかを確認 (削除検討)
    func checkAndClearBackgroundCompletionFlag() -> Bool {
        print("⚠️ checkAndClearBackgroundCompletionFlag is likely obsolete with AsyncStream.")
        return false // 削除までの暫定
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    func extendedRuntimeSession(
        _: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        print("拡張ランタイムセッションが無効化されました。理由: \(reason), エラー: \(String(describing: error))")
        completionContinuation?.finish() // ストリーム終了
        completionContinuation = nil
        session = nil
    }

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("拡張ランタイムセッションが開始されました (Delegate)")
        self.session = session
    }

    func extendedRuntimeSessionWillExpire(_: WKExtendedRuntimeSession) {
        print("拡張ランタイムセッションがまもなく期限切れになります -> 完了イベント発行")
        completionContinuation?.yield(()) // 完了イベント発行
        completionContinuation?.finish() // ストリーム終了
        completionContinuation = nil
        session = nil
    }
}

// MARK: - TCA Dependency

extension DependencyValues {
    var extendedRuntimeService: ExtendedRuntimeServiceProtocol {
        get { self[ExtendedRuntimeServiceKey.self] }
        set { self[ExtendedRuntimeServiceKey.self] = newValue }
    }
}

private enum ExtendedRuntimeServiceKey: DependencyKey {
    static let liveValue: ExtendedRuntimeServiceProtocol = LiveExtendedRuntimeService()
    static let previewValue: ExtendedRuntimeServiceProtocol = PreviewExtendedRuntimeService()
}

// TestDependencyKey を使用して testValue を定義
extension LiveExtendedRuntimeService: TestDependencyKey {
    static let testValue: ExtendedRuntimeServiceProtocol = {
        struct UnimplementedExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
            // unimplemented(_:placeholder:) 形式で修正
            let completionEvents: AsyncStream<Void> = unimplemented(
                "\(Self.self).completionEvents",
                placeholder: .finished // AsyncStream<Void>.finished をプレースホルダーに
            )

            func startSession(duration _: TimeInterval, targetEndTime _: Date?) {
                unimplemented(
                    "\(Self.self).startSession",
                    placeholder: () // Void のプレースホルダー
                )
            }

            func stopSession() {
                unimplemented(
                    "\(Self.self).stopSession",
                    placeholder: () // Void のプレースホルダー
                )
            }

            func checkAndClearBackgroundCompletionFlag() -> Bool {
                unimplemented(
                    "\(Self.self).checkAndClearBackgroundCompletionFlag",
                    placeholder: false // Bool のプレースホルダー
                )
            }
        }
        return UnimplementedExtendedRuntimeService()
    }()
}
