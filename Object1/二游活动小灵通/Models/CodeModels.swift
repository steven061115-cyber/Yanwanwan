import Foundation

// MARK: - API Response
// Actual format from api.ennead.cc/mihoyo/{game}/codes:
// { "active": [{ "code": "...", "rewards": ["..."] }], "inactive": [...] }

struct CodeResponse: Codable {
    let active:   [APICode]
    let inactive: [APICode]

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        active   = (try? c.decode([APICode].self, forKey: .active))   ?? []
        inactive = (try? c.decode([APICode].self, forKey: .inactive)) ?? []
    }
}

struct APICode: Codable {
    let code:    String
    let rewards: [String]?
}

// MARK: - Display Model

struct ExchangeCode: Identifiable, Hashable {
    let id:       String   // "{game}_{code}"
    let game:     HoYoGame
    let code:     String
    let rewards:  [String]
    let isActive: Bool

    var redemptionURL: URL? {
        switch game {
        case .genshin:  return URL(string: "https://genshin.mihoyo.com/gift?code=\(code)")
        case .starrail: return URL(string: "https://sr.mihoyo.com/gift?code=\(code)")
        }
    }

    var rewardsText: String {
        rewards.isEmpty ? "兑换奖励" : rewards.joined(separator: "  ")
    }

    // 前瞻直播码特征：奖励 ≤ 3 项，且包含该游戏的主要货币
    var isLivestreamCode: Bool {
        let currency: String
        switch game {
        case .genshin:  currency = "Primogem"
        case .starrail: currency = "Stellar Jade"
        }
        return rewards.count <= 3 && rewards.contains(where: { $0.contains(currency) })
    }

    static func from(_ a: APICode, game: HoYoGame, isActive: Bool) -> ExchangeCode {
        ExchangeCode(
            id:       "\(game.rawValue)_\(a.code)",
            game:     game,
            code:     a.code,
            rewards:  a.rewards ?? [],
            isActive: isActive
        )
    }
}
