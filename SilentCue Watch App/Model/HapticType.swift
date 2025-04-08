import Foundation

enum HapticType: String, Equatable, CaseIterable, Identifiable {
    case `default` = "standard"
    case notification = "gentle"
    case success = "strong"
    case warning = "double"
    case failure = "alert"
    
    var id: String { self.rawValue }
} 