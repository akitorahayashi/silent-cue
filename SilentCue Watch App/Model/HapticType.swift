import Foundation
import WatchKit

enum HapticType: String, Equatable, CaseIterable, Identifiable {
    case standard = "Standard"
    case strong = "Strong"
    case weak = "Weak"
    case fast = "Fast"
    case slow = "Slow"
    
    var id: String { self.rawValue }
    
    var wkHapticType: WKHapticType {
        switch self {
        case .standard: return .notification
        case .strong: return .success
        case .weak: return .directionUp
        case .fast: return .directionDown
        case .slow: return .click
        }
    }
} 