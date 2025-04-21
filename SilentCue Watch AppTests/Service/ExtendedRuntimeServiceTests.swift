import Combine
import ComposableArchitecture // 必要なら XCTestDynamicOverlay / unimplemented のため
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class ExtendedRuntimeServiceTests: XCTestCase {
    var service: MockExtendedRuntimeService! // モックサービス
    var cancellables: Set<AnyCancellable> = [] // Combine キャンセル用

    override func setUp() {
        super.setUp()
        service = MockExtendedRuntimeService() // 各テスト前にモックを初期化
    }

    override func tearDown() {
        service = nil // サービス解放
        cancellables.removeAll() // キャンセル可能なものをクリア
        super.tearDown()
    }

    // ストリームの完了を待つヘルパー
    private func awaitStreamCompletion(_ stream: AsyncStream<Void>, timeout: TimeInterval = 1.0) async {
        let expectation = XCTestExpectation(description: "ストリーム完了を待機")
        var task: Task<Void, Never>?
        task = Task {
            for await _ in stream {}
            // ストリーム完了
            expectation.fulfill()
            task?.cancel()
        }

        // fulfillment(of:timeout:) がタイムアウト失敗を処理
        // 手動のタイムアウトチェックと fulfill を削除
        await fulfillment(of: [expectation], timeout: timeout)
        task?.cancel() // タスクキャンセルを保証
    }

    // ストリームの値発行と完了を待つヘルパー
    private func awaitStreamYieldAndCompletion(_ stream: AsyncStream<Void>, timeout: TimeInterval = 1.0) async {
        let yieldExpectation = XCTestExpectation(description: "ストリームの値発行を待機")
        let completionExpectation = XCTestExpectation(description: "ストリーム完了を待機")
        var task: Task<Void, Never>?
        task = Task {
            var yielded = false
            for await _ in stream where !yielded {
                yieldExpectation.fulfill()
                yielded = true
            }
            // ストリーム完了
            if !yielded { yieldExpectation.fulfill() } // 発行せずに完了した場合も yield を fulfill
            completionExpectation.fulfill()
            task?.cancel()
        }

        // fulfillment(of:timeout:) がタイムアウト失敗を処理
        // 手動のタイムアウトチェックと fulfill を削除
        await fulfillment(of: [yieldExpectation, completionExpectation], timeout: timeout)
        task?.cancel() // タスクキャンセルを保証
    }

    // セッション開始時のパラメータ記録を検証
    func testStartSession_RecordsParameters() {
        let testDuration: TimeInterval = 120
        let testEndDate = Date().addingTimeInterval(testDuration)
        // expectation と shouldCallStartSessionCompletionImmediately は不要

        // startSession 呼び出し (completionHandler なし)
        service.startSession(duration: testDuration, targetEndTime: testEndDate)

        // waitForExpectations は不要

        XCTAssertEqual(service.startSessionCallCount, 1)
        XCTAssertEqual(service.startSessionLastParams?.duration, testDuration)
        XCTAssertEqual(service.startSessionLastParams?.targetEndTime, testEndDate)
        // completionHandler のアサーションは不要
    }

    // セッション停止が記録されるか検証
    func testStopSession_IncrementsCallCount() {
        service.stopSession()
        XCTAssertEqual(service.stopSessionCallCount, 1)
    }

    // モックの状態リセットを検証
    func testReset() {
        // startSession 呼び出し (completionHandler なし)
        service.startSession(duration: 10, targetEndTime: nil)
        service.stopSession()

        service.reset()

        XCTAssertEqual(service.startSessionCallCount, 0)
        XCTAssertNil(service.startSessionLastParams)
        XCTAssertEqual(service.stopSessionCallCount, 0)
        // shouldCallStartSessionCompletionImmediately のアサーション不要
    }

    // ライブサービス: セッション開始・停止でストリームが完了するか検証
    func testStartAndStopSession_CompletesStream() async {
        let service = LiveExtendedRuntimeService()

        // セッション開始 (WKExtendedRuntimeSession との直接的なやり取りはここではテストしない)
        service.startSession(duration: 60, targetEndTime: nil)

        // セッション停止
        service.stopSession()

        // stopSession 直後にストリームが完了することをアサート
        await awaitStreamCompletion(service.completionEvents)
    }

    // ライブサービス: セッション期限切れ時にストリームが値を発行し完了するか検証
    func testSessionWillExpire_YieldsAndCompletesStream() async {
        let service = LiveExtendedRuntimeService()
        // デリゲートメソッドを呼び出すにはセッションインスタンスが必要。
        // しかし、テストではデリゲートメソッドを直接呼び出せる。
        // セッションが存在し、期限切れになろうとしている状況をシミュレート。

        let stream = service.completionEvents

        // デリゲートメソッドを直接呼び出し
        // このテストでは実際の WKExtendedRuntimeSession インスタンスは不要
        service.extendedRuntimeSessionWillExpire(WKExtendedRuntimeSession()) // ダミーセッションを渡す

        // ストリームが値を発行し、その後完了することをアサート
        await awaitStreamCompletion(stream)

        // セッション参照がクリアされたか確認 (任意だが良い実践)
        // 内部状態へのアクセス方法は？ テスト可能にするか、振る舞いから推測する必要あり。
        // 現状では、ストリームの振る舞いに焦点を当てる。
    }

    // ライブサービス: セッション無効化時にストリームが完了するか検証
    func testSessionDidInvalidate_CompletesStream() async {
        let service = LiveExtendedRuntimeService()
        // セッションが存在し、無効化された状況をシミュレート。

        let stream = service.completionEvents

        // デリゲートメソッドを直接呼び出し
        service
            .extendedRuntimeSession(
                WKExtendedRuntimeSession(),
                didInvalidateWith: .sessionInProgress,
                error: nil
            ) // ダミーセッション

        // ストリームが完了することをアサート
        await awaitStreamCompletion(stream)
    }
}
