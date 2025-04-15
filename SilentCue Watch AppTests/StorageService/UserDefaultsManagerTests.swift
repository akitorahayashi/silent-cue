@testable import SilentCue_Watch_App
import XCTest

class UserDefaultsManagerTests: XCTestCase {
    var userDefaultsManager: UserDefaultsManager! // 実装クラスを使用
    let testDefaults = UserDefaults.standard // テスト対象のUserDefaults

    override func setUp() {
        super.setUp()
        // 各テストの前に新しいインスタンスを作成
        userDefaultsManager = UserDefaultsManager.shared // sharedインスタンスをテスト
        // 必要であれば、テスト用に別のUserDefaults suiteを使うことも可能
        // testDefaults = UserDefaults(suiteName: "TestDefaults")!
    }

    override func tearDown() {
        // 各テストの後にテストで使用したキーをクリーンアップ
        for item in UserDefaultsKeys.allCases {
            testDefaults.removeObject(forKey: item.rawValue)
        }
        userDefaultsManager = nil
        super.tearDown()
    }

    func testSetAndGetObject() {
        // Bool値の保存と取得
        let keyBool = UserDefaultsKeys.stopVibrationAutomatically
        userDefaultsManager.set(true, forKey: keyBool)
        // 直接 UserDefaults.standard からも確認
        XCTAssertEqual(testDefaults.bool(forKey: keyBool.rawValue), true)
        // マネージャー経由で取得
        XCTAssertEqual(userDefaultsManager.object(forKey: keyBool) as? Bool, true)

        // String値の保存と取得
        let keyString = UserDefaultsKeys.hapticType
        let testValue = HapticType.strong.rawValue
        userDefaultsManager.set(testValue, forKey: keyString)
        XCTAssertEqual(testDefaults.string(forKey: keyString.rawValue), testValue)
        XCTAssertEqual(userDefaultsManager.object(forKey: keyString) as? String, testValue)

        // 値の上書き
        userDefaultsManager.set(false, forKey: keyBool)
        XCTAssertEqual(testDefaults.bool(forKey: keyBool.rawValue), false)
        XCTAssertEqual(userDefaultsManager.object(forKey: keyBool) as? Bool, false)

        // nilの保存 (削除と同じ効果)
        userDefaultsManager.set(nil, forKey: keyString)
        XCTAssertNil(testDefaults.string(forKey: keyString.rawValue))
        XCTAssertNil(userDefaultsManager.object(forKey: keyString))
    }

    func testRemoveObject() {
        let keyBool = UserDefaultsKeys.stopVibrationAutomatically
        let keyString = UserDefaultsKeys.hapticType

        // 初期値を設定
        userDefaultsManager.set(true, forKey: keyBool)
        userDefaultsManager.set(HapticType.standard.rawValue, forKey: keyString)

        // 1つ削除
        userDefaultsManager.remove(forKey: keyBool)
        XCTAssertNil(testDefaults.object(forKey: keyBool.rawValue))
        XCTAssertNil(userDefaultsManager.object(forKey: keyBool))
        // もう一方は残っていることを確認
        XCTAssertNotNil(testDefaults.object(forKey: keyString.rawValue))
        XCTAssertNotNil(userDefaultsManager.object(forKey: keyString))

        // 存在しないキーを削除してもエラーにならないこと
        userDefaultsManager.remove(forKey: keyBool) // 再度削除
        XCTAssertNil(userDefaultsManager.object(forKey: keyBool))
    }

    func testRemoveAll() {
        let keyBool = UserDefaultsKeys.stopVibrationAutomatically
        let keyString = UserDefaultsKeys.hapticType

        // 初期値を設定
        userDefaultsManager.set(true, forKey: keyBool)
        userDefaultsManager.set(HapticType.standard.rawValue, forKey: keyString)

        // 全て削除
        userDefaultsManager.removeAll()

        // 全てのキーの値がnilになっていることを確認
        for item in UserDefaultsKeys.allCases {
            XCTAssertNil(testDefaults.object(forKey: item.rawValue))
            XCTAssertNil(userDefaultsManager.object(forKey: item))
        }
    }

    func testGetObjectForNonExistentKey() {
        // 何も設定していないキーに対して object(forKey:) を呼ぶ
        let keyBool = UserDefaultsKeys.stopVibrationAutomatically
        XCTAssertNil(userDefaultsManager.object(forKey: keyBool))
    }
}
