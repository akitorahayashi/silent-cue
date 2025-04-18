import ComposableArchitecture
import Foundation
import WatchKit
import XCTestDynamicOverlay // Import for XCTFail

/// バックグラウンド実行をサポートする拡張ランタイムセッション管理クラス (ライブ実装)
final class LiveExtendedRuntimeService: NSObject, WKExtendedRuntimeSessionDelegate, ExtendedRuntimeServiceProtocol {
    /// 現在のセッション
    private var session: WKExtendedRuntimeSession?

    /// タイマー完了時のコールバック
    private var timerCompletionHandler: (() -> Void)?

    /// バックグラウンドでタイマーが完了したかのフラグ
    private(set) var isTimerCompletedInBackground = false

    /// 終了予定時間
    private var targetEndTime: Date?

    /// バックグラウンドチェックタイマー
    private var backgroundTimer: Timer?

    /// 拡張ランタイムセッションを開始する
    func startSession(duration _: TimeInterval, targetEndTime: Date? = nil, completionHandler: (() -> Void)? = nil) {
        // 既存のセッションを終了
        stopSession()

        // バックグラウンド完了フラグをリセット
        isTimerCompletedInBackground = false

        // コールバックと終了時間を保存
        timerCompletionHandler = completionHandler
        self.targetEndTime = targetEndTime

        // 新しいセッションを開始
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        self.session = session

        // バックグラウンドでの定期チェックを開始
        startBackgroundTimer()

        print("Extended runtime session started")
    }

    /// 拡張ランタイムセッションを停止する
    func stopSession() {
        session?.invalidate()
        session = nil

        // バックグラウンドタイマーを停止
        stopBackgroundTimer()

        // フラグをリセット
        isTimerCompletedInBackground = false

        print("Extended runtime session stopped")
    }

    /// バックグラウンドチェックタイマーを開始
    private func startBackgroundTimer() {
        // 既存のタイマーを停止
        stopBackgroundTimer()

        // 1秒ごとに終了時間をチェックするタイマーを設定
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkTimerCompletion()
        }
    }

    /// バックグラウンドチェックタイマーを停止
    private func stopBackgroundTimer() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }

    /// タイマー完了をチェックする
    private func checkTimerCompletion() {
        guard let targetEndTime,
              let completionHandler = timerCompletionHandler
        else {
            return
        }

        // 現在時刻が終了予定時刻を過ぎていたらコールバックを実行
        if Date() >= targetEndTime {
            print("Timer completed in background")
            // バックグラウンド完了フラグを設定
            isTimerCompletedInBackground = true
            completionHandler()

            // 一度だけ実行するように参照をクリア
            timerCompletionHandler = nil
        }
    }

    /// アプリがフォアグラウンドに戻ったときに呼び出して、バックグラウンドでタイマーが完了していたかを確認
    func checkAndClearBackgroundCompletionFlag() -> Bool {
        let wasCompleted = isTimerCompletedInBackground
        isTimerCompletedInBackground = false
        return wasCompleted
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    func extendedRuntimeSession(
        _: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error _: Error?
    ) {
        print("Extended runtime session invalidated with reason: \(reason)")
    }

    func extendedRuntimeSessionDidStart(_: WKExtendedRuntimeSession) {
        print("Extended runtime session did start")
    }

    func extendedRuntimeSessionWillExpire(_: WKExtendedRuntimeSession) {
        print("Extended runtime session will expire")
    }

    // public init (DependencyKeyで使用)
    override public init() {
        super.init()
    }
}

// MARK: - TCA Dependency

extension DependencyValues {
    var extendedRuntimeService: ExtendedRuntimeServiceProtocol { // Rename property, update type and key
        get { self[ExtendedRuntimeServiceKey.self] }
        set { self[ExtendedRuntimeServiceKey.self] = newValue }
    }
}

private enum ExtendedRuntimeServiceKey: DependencyKey { // Rename key enum
    static let liveValue: ExtendedRuntimeServiceProtocol = LiveExtendedRuntimeService() // Use new class and protocol

    // Use Noop for previews
    static let previewValue: ExtendedRuntimeServiceProtocol =
        NoopExtendedRuntimeService() // Update to use renamed NoopExtendedRuntimeService
}

// TestDependencyKey を使用して testValue を定義
extension LiveExtendedRuntimeService: TestDependencyKey { // Update extension target
    static let testValue: ExtendedRuntimeServiceProtocol = { // Update protocol type
        struct UnimplementedExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
            // Rename struct, conform to new protocol
            func startSession(duration _: TimeInterval, targetEndTime _: Date?, completionHandler _: (() -> Void)?) {
                XCTFail("\(Self.self).startSession is unimplemented")
            }

            func stopSession() {
                XCTFail("\(Self.self).stopSession is unimplemented")
            }

            func checkAndClearBackgroundCompletionFlag() -> Bool {
                XCTFail("\(Self.self).checkAndClearBackgroundCompletionFlag is unimplemented")
                return false // Placeholder return
            }
        }
        return UnimplementedExtendedRuntimeService()
    }()
}
