@testable import SilentCue_Watch_App
import XCTest

class UserDefaultsServiceTests: XCTestCase {
    var userDefaultsService: MockUserDefaultsManager!

    override func setUp() {
        super.setUp()
        userDefaultsService = MockUserDefaultsManager()
    }

    override func tearDown() {
        userDefaultsService.removeAll()
        userDefaultsService = nil
        super.tearDown()
    }

    // 様々な型の値の設定と取得を検証
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

    // 指定したキーの値の削除を検証
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

    // 全てのキーと値の削除を検証
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

    // 値に nil を設定するとキーが削除されるか検証
    func testSetNilRemovesObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        userDefaultsService.set(true, forKey: keyBool)
        XCTAssertNotNil(userDefaultsService.object(forKey: keyBool))

        // nilを設定するとオブジェクトが削除されるはず
        userDefaultsService.set(nil, forKey: keyBool)
        XCTAssertNil(userDefaultsService.object(forKey: keyBool))
        XCTAssertNil(userDefaultsService.getAllValues()[keyBool.rawValue])
    }

    // 存在しないキーの値を取得すると nil が返るか検証
    func testGetObjectNotFound() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        XCTAssertNil(userDefaultsService.object(forKey: keyBool))
    }
}
