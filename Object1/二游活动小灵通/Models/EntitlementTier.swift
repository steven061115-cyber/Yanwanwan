import Foundation

enum EntitlementTier: String, Codable, Sendable {
    case free
    case premium

    var displayName: String {
        switch self {
        case .free:    return String(localized: "免费版", bundle: .appLanguage)
        case .premium: return String(localized: "会员", bundle: .appLanguage)
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
        case .free:    return 2
        case .premium: return 5
        }
    }

    var extractionLimitTitle: String {
        switch self {
        case .free:    return String(localized: "免费提取次数已用完", bundle: .appLanguage)
        case .premium: return String(localized: "会员提取次数已用完", bundle: .appLanguage)
        }
    }

    var extractionLimitMessage: String {
        switch self {
        case .free:
            return String(localized: "免费版今日 \(dailyAIQueries) 次提取额度已用完。升级会员后每日可提取 \(EntitlementTier.premium.dailyAIQueries) 次。", bundle: .appLanguage)
        case .premium:
            return String(localized: "会员今日 \(dailyAIQueries) 次提取额度已用完，明天会自动恢复。", bundle: .appLanguage)
        }
    }

    func customGameLimitMessage(currentCount: Int) -> String {
        switch self {
        case .free:
            return String(localized: "免费版最多只能添加 1 个自定义游戏。当前已有 \(currentCount) 个，升级会员可添加 10 个。", bundle: .appLanguage)
        case .premium:
            return String(localized: "会员最多可添加 \(maxCustomGames) 个自定义游戏。当前已有 \(currentCount) 个，请先删除不需要的游戏后再添加。", bundle: .appLanguage)
        }
    }
}
