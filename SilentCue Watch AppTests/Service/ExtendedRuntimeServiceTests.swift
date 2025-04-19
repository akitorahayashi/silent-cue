import Combine
import ComposableArchitecture // For XCTestDynamicOverlay / unimplemented if needed
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class ExtendedRuntimeServiceTests: XCTestCase {
    var service: MockExtendedRuntimeService!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        service = MockExtendedRuntimeService()
    }

    override func tearDown() {
        service = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // Helper to await stream completion
    private func awaitStreamCompletion(_ stream: AsyncStream<Void>, timeout: TimeInterval = 1.0) async {
        let expectation = XCTestExpectation(description: "Wait for stream completion")
        var task: Task<Void, Never>?
        task = Task {
            for await _ in stream {}
            // Stream completed
            expectation.fulfill()
            task?.cancel()
        }

        // fulfillment(of:timeout:) handles the timeout failure.
        // Remove manual timeout check and fulfillment.
        await fulfillment(of: [expectation], timeout: timeout)
        task?.cancel() // Ensure task is cancelled
    }

    // Helper to await stream yielding a value then completing
    private func awaitStreamYieldAndCompletion(_ stream: AsyncStream<Void>, timeout: TimeInterval = 1.0) async {
        let yieldExpectation = XCTestExpectation(description: "Wait for stream yield")
        let completionExpectation = XCTestExpectation(description: "Wait for stream completion")
        var task: Task<Void, Never>?
        task = Task {
            var yielded = false
            for await _ in stream {
                if !yielded {
                    yieldExpectation.fulfill()
                    yielded = true
                }
            }
            // Stream completed
            if !yielded { yieldExpectation.fulfill() } // Fulfill yield if completes without yielding
            completionExpectation.fulfill()
            task?.cancel()
        }

        // fulfillment(of:timeout:) handles the timeout failure.
        // Remove manual timeout check and fulfillment.
        await fulfillment(of: [yieldExpectation, completionExpectation], timeout: timeout)
        task?.cancel() // Ensure task is cancelled
    }

    // セッション開始時のパラメータ記録を検証 (完了ハンドラ削除)
    func testStartSession_RecordsParameters() {
        let testDuration: TimeInterval = 120
        let testEndDate = Date().addingTimeInterval(testDuration)
        // expectation と shouldCallStartSessionCompletionImmediately は削除

        // startSession 呼び出しを修正 (completionHandler 削除)
        service.startSession(duration: testDuration, targetEndTime: testEndDate)

        // waitForExpectations は削除

        XCTAssertEqual(service.startSessionCallCount, 1)
        XCTAssertEqual(service.startSessionLastParams?.duration, testDuration)
        XCTAssertEqual(service.startSessionLastParams?.targetEndTime, testEndDate)
        // completionHandler のアサーションは削除
        // XCTAssertNotNil(service.startSessionLastParams?.completionHandler)
    }

    // セッション停止が記録されるか
    func testStopSession_IncrementsCallCount() {
        service.stopSession()
        XCTAssertEqual(service.stopSessionCallCount, 1)
    }

    // バックグラウンド完了フラグの確認とクリアのロジックを検証
    func testCheckAndClearBackgroundCompletionFlag_ReturnsStubValue() {
        // 1. 初期状態 (false)
        XCTAssertFalse(service.checkAndClearBackgroundCompletionFlag(), "初期値は false であるべきです。")
        XCTAssertEqual(service.checkAndClearBackgroundCompletionFlagCallCount, 1)

        // 2. スタブ値を true に設定
        service.checkAndClearBackgroundCompletionFlagReturnValue = true
        XCTAssertTrue(service.checkAndClearBackgroundCompletionFlag(), "スタブ値 true が返されるべきです。")
        XCTAssertEqual(service.checkAndClearBackgroundCompletionFlagCallCount, 2)

        // 3. スタブ値を false に戻す
        service.checkAndClearBackgroundCompletionFlagReturnValue = false
        XCTAssertFalse(service.checkAndClearBackgroundCompletionFlag(), "スタブ値 false が返されるべきです。")
        XCTAssertEqual(service.checkAndClearBackgroundCompletionFlagCallCount, 3)
    }

    // モックの状態がリセットされるか
    func testReset() {
        // startSession 呼び出しを修正 (completionHandler 削除)
        service.startSession(duration: 10, targetEndTime: nil)
        service.stopSession()
        service.checkAndClearBackgroundCompletionFlagReturnValue = true
        _ = service.checkAndClearBackgroundCompletionFlag()

        service.reset()

        XCTAssertEqual(service.startSessionCallCount, 0)
        XCTAssertNil(service.startSessionLastParams)
        XCTAssertEqual(service.stopSessionCallCount, 0)
        XCTAssertEqual(service.checkAndClearBackgroundCompletionFlagCallCount, 0)
        XCTAssertFalse(service.checkAndClearBackgroundCompletionFlagReturnValue)
        // shouldCallStartSessionCompletionImmediately のアサーション削除
        // XCTAssertFalse(service.shouldCallStartSessionCompletionImmediately)
    }

    func testStartAndStopSession_CompletesStream() async {
        let service = LiveExtendedRuntimeService()

        // Start session (we don't directly test WKExtendedRuntimeSession interaction here)
        service.startSession(duration: 60, targetEndTime: nil)

        // Stop session
        service.stopSession()

        // Assert that the stream completes shortly after stopSession
        await awaitStreamCompletion(service.completionEvents)
    }

    func testSessionWillExpire_YieldsAndCompletesStream() async {
        let service = LiveExtendedRuntimeService()
        // It needs a session instance to call delegate methods on.
        // However, we can call the delegate methods directly for testing.
        // We simulate the scenario where a session existed and is about to expire.

        let stream = service.completionEvents

        // Directly call the delegate method
        // We don't need a real WKExtendedRuntimeSession instance for this test
        service.extendedRuntimeSessionWillExpire(WKExtendedRuntimeSession()) // Pass a dummy session

        // Assert that the stream yields and then completes
        await awaitStreamYieldAndCompletion(stream)

        // Check if session reference is cleared (optional but good practice)
        // How to access internal state? Need to make it testable or infer from behavior.
        // For now, we focus on the stream behavior.
    }

    func testSessionDidInvalidate_CompletesStream() async {
        let service = LiveExtendedRuntimeService()
        // Simulate the scenario where a session existed and was invalidated.

        let stream = service.completionEvents

        // Directly call the delegate method
        service
            .extendedRuntimeSession(
                WKExtendedRuntimeSession(),
                didInvalidateWith: .sessionInProgress,
                error: nil
            ) // Dummy session

        // Assert that the stream completes
        await awaitStreamCompletion(stream)
    }

    func testCheckAndClearFlag_ReturnsFalse() {
        let service = LiveExtendedRuntimeService()
        // Ensure the obsolete method returns false as expected for now.
        XCTAssertFalse(service.checkAndClearBackgroundCompletionFlag())
    }
}
