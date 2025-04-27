import Combine
import ComposableArchitecture
import SCMock
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
        await fulfillment(of: [yieldExpectation, completionExpectation], timeout: timeout)
        task?.cancel() // タスクキャンセルを保証
    }

    // セッション開始時のパラメータ記録を検証
    func testStartSession_RecordsParameters() {
        let testDuration: TimeInterval = 120
        let testEndDate = Date().addingTimeInterval(testDuration)

        // startSession 呼び出し (completionHandler なし)
        service.startSession(duration: testDuration, targetEndTime: testEndDate)

        XCTAssertEqual(service.startSessionCallCount, 1)
        XCTAssertEqual(service.lastStartSessionDuration, testDuration)
        XCTAssertEqual(service.lastStartSessionTargetEndTime, testEndDate)
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
        XCTAssertNil(service.lastStartSessionDuration)
        XCTAssertNil(service.lastStartSessionTargetEndTime)
        XCTAssertEqual(service.stopSessionCallCount, 0)
    }
}
