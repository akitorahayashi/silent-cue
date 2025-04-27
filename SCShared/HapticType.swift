import Foundation
import WatchKit

public enum HapticType: String, Equatable, CaseIterable, Identifiable {
    case standard = "Standard"
    case strong = "Strong"
    case weak = "Weak"

    public var id: String { rawValue }

    public var wkHapticType: WKHapticType {
        switch self {
            case .standard: return .success
            case .strong: return .retry
            case .weak: return .directionUp
        }
    }

    // 振動の間隔（秒）
    public var interval: TimeInterval {
        switch self {
            case .standard: return 0.5
            case .strong: return 0.7
            case .weak: return 0.9
        }
    }

    // 振動の強さ（0.0〜1.0）
    public var intensity: Float {
        switch self {
            case .standard: return 0.7
            case .strong: return 1.0
            case .weak: return 0.3
        }
    }
}
