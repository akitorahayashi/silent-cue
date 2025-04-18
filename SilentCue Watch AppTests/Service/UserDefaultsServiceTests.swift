@testable import SilentCue_Watch_App
import XCTest

class UserDefaultsServiceTests: XCTestCase {
    var userDefaultsService: MockUserDefaultsManager!

    override func setUp() {
        super.setUp()
        // モック実装を使用
        userDefaultsService = MockUserDefaultsManager()
        // 各テストの前にUserDefaults(モック)をクリーンアップ
        // userDefaultsService.removeAll() // Mock の init で空になるので不要かも
    }

    override func tearDown() {
        // 各テストの後にUserDefaults(モック)をクリーンアップ
        userDefaultsService.removeAll() // tearDown では念のため呼ぶ
        userDefaultsService = nil
        super.tearDown()
    }

    // MARK: - テストケース

    func testSetAndGetObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let valueBool = true
        userDefaultsService.set(valueBool, forKey: keyBool)
        XCTAssertEqual(userDefaultsService.object(forKey: keyBool) as? Bool, valueBool)

        let keyString = UserDefaultsKeys.hapticType
        let valueString = "strong"
        userDefaultsService.set(valueString, forKey: keyString)
        XCTAssertEqual(userDefaultsService.object(forKey: keyString) as? String, valueString)

        // Mock固有のメソッドで内部状態を確認する
        let internalStorage = userDefaultsService.getAllValues()
        XCTAssertEqual(internalStorage[keyBool.rawValue] as? Bool, valueBool)
        XCTAssertEqual(internalStorage[keyString.rawValue] as? String, valueString)
    }

    func testRemoveObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let keyString = UserDefaultsKeys.hapticType
        userDefaultsService.set(true, forKey: keyBool)
        userDefaultsService.set("testHaptic", forKey: keyString)

        userDefaultsService.remove(forKey: keyBool)
        XCTAssertNil(userDefaultsService.object(forKey: keyBool))
        XCTAssertNotNil(userDefaultsService.object(forKey: keyString)) // Stringはまだ存在
        XCTAssertNil(userDefaultsService.getAllValues()[keyBool.rawValue])

        userDefaultsService.remove(forKey: keyString)
        XCTAssertNil(userDefaultsService.object(forKey: keyString))
        XCTAssertTrue(userDefaultsService.getAllValues().isEmpty) // 両方削除されたので空のはず
    }

    func testRemoveAll() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let keyString = UserDefaultsKeys.hapticType
        userDefaultsService.set(true, forKey: keyBool)
        userDefaultsService.set("testHaptic", forKey: keyString)

        XCTAssertFalse(userDefaultsService.getAllValues().isEmpty) // 値があることを確認
        userDefaultsService.removeAll()

        XCTAssertNil(userDefaultsService.object(forKey: keyBool))
        XCTAssertNil(userDefaultsService.object(forKey: keyString))
        XCTAssertTrue(userDefaultsService.getAllValues().isEmpty) // removeAll で空になることを確認
    }

    func testSetNilRemovesObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        userDefaultsService.set(true, forKey: keyBool)
        XCTAssertNotNil(userDefaultsService.object(forKey: keyBool))

        // nilを設定するとオブジェクトが削除されるはず
        userDefaultsService.set(nil, forKey: keyBool)
        XCTAssertNil(userDefaultsService.object(forKey: keyBool))
        XCTAssertNil(userDefaultsService.getAllValues()[keyBool.rawValue])
    }

    func testGetObjectNotFound() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        XCTAssertNil(userDefaultsService.object(forKey: keyBool))
    }
}
