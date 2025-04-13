//
//  SilentCue_Watch_AppUITests.swift
//  SilentCue Watch AppUITests
//
//  Created by akitora.hayashi on 2025/04/06.
//

import XCTest

final class SilentCueWatchAppUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
    }

    func testTimerFlow() throws {
        // タイマー関連のUIテストをすべて実行
        let timerTests = TimerUITests()
        timerTests.setUp()
        try timerTests.testTimerSetupAndCancel()
        try timerTests.testTimeModeSelection()
        try timerTests.testSettingsNavigation()
    }

    func testSettingsFlow() throws {
        // 設定関連のUIテストをすべて実行
        let settingsTests = SettingsUITests()
        settingsTests.setUp()
        try settingsTests.testToggleAutoStop()
        try settingsTests.testHapticTypeSelection()
        try settingsTests.testDangerZone()
        try settingsTests.testNavigationBack()
    }

    func testCompletionFlow() throws {
        // 完了画面のUIテストをすべて実行
        let completionTests = CompletionUITests()
        completionTests.setUp()
        try completionTests.testCompletionViewElements()
        try completionTests.testCompletionViewAnimation()
    }
}
