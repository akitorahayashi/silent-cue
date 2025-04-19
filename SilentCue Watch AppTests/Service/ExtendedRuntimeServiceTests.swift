@testable import SilentCue_Watch_App
import WatchKit
import XCTest

class ExtendedRuntimeServiceTests: XCTestCase {
    var service: MockExtendedRuntimeService!

    override func setUp() {
        super.setUp()
        service = MockExtendedRuntimeService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // セッション開始時のパラメータ記録と完了ハンドラの呼び出しを検証
    func testStartSession_RecordsParameters() {
        let testDuration: TimeInterval = 120
        let testEndDate = Date().addingTimeInterval(testDuration)
        let expectation = expectation(description: "完了ハンドラが呼び出されました")
        service.shouldCallStartSessionCompletionImmediately = true // モックで完了ハンドラを即時呼び出し

        service.startSession(duration: testDuration, targetEndTime: testEndDate) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1) // 即時呼び出しなので短いタイムアウト

        XCTAssertEqual(service.startSessionCallCount, 1)
        XCTAssertEqual(service.startSessionLastParams?.duration, testDuration)
        XCTAssertEqual(service.startSessionLastParams?.targetEndTime, testEndDate)
        XCTAssertNotNil(service.startSessionLastParams?.completionHandler)
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
        service.startSession(duration: 10, targetEndTime: nil, completionHandler: nil)
        service.stopSession()
        service.checkAndClearBackgroundCompletionFlagReturnValue = true
        _ = service.checkAndClearBackgroundCompletionFlag()

        service.reset()

        XCTAssertEqual(service.startSessionCallCount, 0)
        XCTAssertNil(service.startSessionLastParams)
        XCTAssertEqual(service.stopSessionCallCount, 0)
        XCTAssertEqual(service.checkAndClearBackgroundCompletionFlagCallCount, 0)
        XCTAssertFalse(service.checkAndClearBackgroundCompletionFlagReturnValue)
        XCTAssertFalse(service.shouldCallStartSessionCompletionImmediately)
    }
}
