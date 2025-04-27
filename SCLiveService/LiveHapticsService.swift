import Dependencies
import WatchKit
import XCTestDynamicOverlay
import Foundation
import SCProtocol

public class LiveHapticsService: HapticsServiceProtocol {
    
    public init() {}
    
    public func play(_ type: Int) {
        guard let hapticType = WKHapticType(rawValue: type) else { return }
        WKInterfaceDevice.current().play(hapticType)
    }
}
