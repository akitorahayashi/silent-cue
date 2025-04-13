//
//  SilentCue_Watch_AppTests.swift
//  SilentCue Watch AppTests
//
//  Created by akitora.hayashi on 2025/04/06.
//

@testable import SilentCue_Watch_App
import XCTest

final class SilentCueWatchAppTests: XCTestCase {
    // この空のクラス宣言は必要です
    // テストバンドルのエントリポイントとして機能します

    // 個々のテストケースは専用のファイルで実装されています
    // - TimerReducerTests
    // - SettingsReducerTests
    // など

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
    }

    func testTimerDomain() {
        // 実際のテストはTimerReducerTestsクラスで実行されます
        // このクラスは構造的なテスト実行のためのものです
    }

    func testSettingsDomain() {
        // 実際のテストはSettingsReducerTestsクラスで実行されます
    }

    func testModels() {
        // 実際のテストはHapticTypeTestsクラスで実行されます
    }

    func testStorageService() {
        // 実際のテストはUserDefaultsManagerTestsクラスで実行されます
    }
}
