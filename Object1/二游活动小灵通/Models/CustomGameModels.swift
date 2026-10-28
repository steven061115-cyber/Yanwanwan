import Foundation
import SwiftData
import SwiftUI

// 分类以中文原文存储和比较，只在显示时翻译。
func localizedEventCategory(_ raw: String) -> String {
    switch raw {
    case "活动":     return String(localized: "活动", bundle: .appLanguage)
    case "挑战":     return String(localized: "挑战", bundle: .appLanguage)
    case "版本活动": return String(localized: "版本活动", bundle: .appLanguage)
    case "周常任务": return String(localized: "周常任务", bundle: .appLanguage)
    case "副本挑战": return String(localized: "副本挑战", bundle: .appLanguage)
    default:         return raw
    }
}

// MARK: - SwiftData Models

@Model
final class CustomGame {
    var id: String
    var name: String
    var emoji: String
    var colorHex: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var events: [CustomEvent]

    init(name: String, emoji: String = "🎮", colorHex: String = "6B7FFF") {
        self.id        = UUID().uuidString
        self.name      = name
        self.emoji     = emoji
        self.colorHex  = colorHex
        self.createdAt = Date()
        self.events    = []
    }

    var accentColor: Color { Color(hex: colorHex) }

    var activeEvents: [CustomEvent] {
        events.filter { $0.remaining > 0 && !$0.isDone }
              .sorted { $0.endDate < $1.endDate }
    }

    var urgentEvent: CustomEvent? {
        activeEvents.min(by: { $0.remaining < $1.remaining })
    }

    @discardableResult
    func replaceEvents(with drafts: [AIEventDraft], in context: ModelContext) -> [String] {
        let oldEvents = events
        let oldEventIds = oldEvents.map(\.id)

        for event in oldEvents {
            context.delete(event)
        }
        events.removeAll()

        for draft in drafts {
            let event = CustomEvent(
                gameId:    id,
                title:     draft.title,
                startDate: draft.startDate,
                endDate:   draft.endDate,
                category:  draft.category
            )
            context.insert(event)
            events.append(event)
        }

        return oldEventIds
    }
}

@Model
final class CustomEvent {
    var id: String
    var gameId: String
    var title: String
    var startDate: Date
    var endDate: Date
    var category: String
    var isDone: Bool

    init(gameId: String, title: String, startDate: Date, endDate: Date, category: String = "活动") {
        self.id        = UUID().uuidString
        self.gameId    = gameId
        self.title     = title
        self.startDate = startDate
        self.endDate   = endDate
        self.category  = category
        self.isDone    = false
    }

    var remaining: TimeInterval { endDate.timeIntervalSinceNow }

    var remainingText: String {
        if isDone { return String(localized: "已完成", bundle: .appLanguage) }
        let rem = Int(remaining)
        if rem <= 0 { return String(localized: "已结束", bundle: .appLanguage) }
        let days  = rem / 86400
        let hours = (rem % 86400) / 3600
        if days > 0 { return String(localized: "剩余 \(days)天 \(hours)时", bundle: .appLanguage) }
        return String(localized: "剩余 \(hours)时", bundle: .appLanguage)
    }

    var endDateShort: String {
        // 按手机所在时区显示，和米哈游游戏的活动一致；国内用户手机就是北京时间。
        let f = DateFormatter()
        f.locale = AppLanguage.current.locale
        let hour   = Calendar.current.component(.hour,   from: endDate)
        let minute = Calendar.current.component(.minute, from: endDate)
        f.setLocalizedDateFormatFromTemplate((hour == 0 && minute == 0) ? "MMMd" : "MMMdHHmm")
        return f.string(from: endDate)
    }

    var urgencyColor: Color {
        if isDone || remaining <= 0 { return .gray }
        if category == "周常任务"   { return .hoyoMint }
        if remaining < 86400        { return .hoyoPink }
        if remaining < 3 * 86400   { return .orange }
        if remaining < 7 * 86400   { return .hoyoMint }
        return .blue
    }
}

// MARK: - Draft (used during AI confirmation, not persisted)

struct AIEventDraft: Identifiable {
    let id = UUID()
    var title: String
    var startDate: Date
    var endDate: Date
    var category: String
    var isSelected: Bool = true

    var endDateShort: String {
        // 按手机所在时区显示，和米哈游游戏的活动一致；国内用户手机就是北京时间。
        let f = DateFormatter()
        f.locale = AppLanguage.current.locale
        let hour   = Calendar.current.component(.hour,   from: endDate)
        let minute = Calendar.current.component(.minute, from: endDate)
        f.setLocalizedDateFormatFromTemplate((hour == 0 && minute == 0) ? "MMMd" : "MMMdHHmm")
        return f.string(from: endDate)
    }
}

// MARK: - Preset color palette

enum CustomGamePalette: String, CaseIterable {
    case violet = "6B7FFF"
    case pink   = "FF4D9E"
    case mint   = "4DDEC4"
    case orange = "FF6B35"
    case yellow = "FFE034"
    case purple = "A855F7"

    var color: Color { Color(hex: rawValue) }
}
