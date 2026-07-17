import Foundation

enum EntitlementTier: String, Codable, Sendable {
    case free
    case premium

    var displayName: String {
        switch self {
        case .free:    return "免费版"
        case .premium: return "会员"
        }
    }

    var maxCustomGames: Int {
        switch self {
        case .free:    return 1
        case .premium: return 10
        }
    }

    var dailyAIQueries: Int {
        switch self {
        case .free:    return 1
        case .premium: return 5
        }
    }

    var backendHeaderValue: String { rawValue }
}
