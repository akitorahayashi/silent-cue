import Foundation
@testable import SilentCue_Watch_App

/// テスト用のUserDefaultsManagerモック
class MockUserDefaultsManager: UserDefaultsManagerProtocol {
    var mockReturnValues: [UserDefaultsKeys: Any] = [:]
    
    func object(forKey defaultName: UserDefaultsKeys) -> Any? {
        return mockReturnValues[defaultName]
    }
    
    func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
        mockReturnValues[defaultName] = value
    }
    
    func remove(forKey defaultName: UserDefaultsKeys) {
        mockReturnValues.removeValue(forKey: defaultName)
    }
} 