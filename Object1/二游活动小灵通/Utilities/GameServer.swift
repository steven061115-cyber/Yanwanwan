import Foundation

// 游戏服务器：决定活动时间换算、App 界面语言、活动数据语言和攻略平台。
// 主 App 和小组件都编译这个文件，设置存在 App Group 里两边共享。
nonisolated enum HoYoServer: String, CaseIterable, Identifiable {
    case china
    case america
    case europe
    case asia

    var id: String { rawValue }

    // 服务器名称不随界面语言变化，任何语言下都能认出自己的服。
    var displayName: String {
        switch self {
        case .china:   return "国服 China"
        case .america: return "美服 America"
        case .europe:  return "欧服 Europe"
        case .asia:    return "亚服 Asia"
        }
    }

    var utcOffsetHours: Int {
        switch self {
        case .america: return -5
        case .europe:  return 1
        case .china, .asia: return 8
        }
    }

    var utcOffsetLabel: String {
        utcOffsetHours >= 0 ? "UTC+\(utcOffsetHours)" : "UTC\(utcOffsetHours)"
    }

    // 国服用 B站，其余服务器用 YouTube。
    var usesBilibili: Bool { self == .china }

    // MARK: Storage

    static let storageKey = "gameServer"
    nonisolated(unsafe) static let store = UserDefaults(suiteName: "group.com.object1.eventreminder") ?? .standard
    // 调试用：在 Xcode Scheme 的启动参数里加 `-GameServerOverride asia` 可临时切换。
    private static let overrideKey = "GameServerOverride"

    static var current: HoYoServer {
        #if DEBUG
        if let override = UserDefaults.standard.string(forKey: overrideKey).flatMap(HoYoServer.init(rawValue:)) {
            return override
        }
        #endif
        if let stored = store.string(forKey: storageKey).flatMap(HoYoServer.init(rawValue:)) {
            return stored
        }
        return guess()
    }

    static func select(_ server: HoYoServer) {
        store.set(server.rawValue, forKey: storageKey)
    }

    // 首次启动时把猜测结果存下来，之后只随用户的选择改变。
    static func saveDefaultIfNeeded() {
        guard store.string(forKey: storageKey) == nil else { return }
        select(guess())
    }

    static func guess(timeZone: TimeZone = .current, region: Locale.Region? = Locale.current.region) -> HoYoServer {
        switch region?.identifier {
        case "CN": return .china
        case "TW", "HK", "MO": return .asia
        default: break
        }
        let hours = Double(timeZone.secondsFromGMT()) / 3600
        if hours <= -3 { return .america }
        if hours < 5   { return .europe }
        return .asia
    }

    // MARK: Time conversion

    // 接口给的是 UTC+8 服务器的时间。每日 04:00 刷新前后（03:59 / 04:00）和活动常规开放时间
    // 10:00 按各服务器本地时间走，换算到所选服务器；版本更新维护等全服同时发生的时间点不动。
    func adjusted(_ date: Date) -> Date {
        let shiftHours = 8 - utcOffsetHours
        guard shiftHours != 0 else { return date }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        let parts = cal.dateComponents([.hour, .minute], from: date)
        let isServerLocalTime = (parts.hour == 3 && parts.minute == 59)
            || (parts.hour == 4 && parts.minute == 0)
            || (parts.hour == 10 && parts.minute == 0)
        return isServerLocalTime ? date.addingTimeInterval(TimeInterval(shiftHours * 3600)) : date
    }
}

// App 界面语言，和服务器无关。首次启动按系统语言选一个，之后只在设置里修改。
nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case en

    var id: String { rawValue }

    static let storageKey = "appLanguage"

    static var current: AppLanguage {
        HoYoServer.store.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:)) ?? guess()
    }

    static func select(_ language: AppLanguage) {
        HoYoServer.store.set(language.rawValue, forKey: storageKey)
    }

    // 首次启动时把系统语言对应的选项存下来，之后系统语言变了也不跟着变。
    static func saveDefaultIfNeeded() {
        guard AppLanguage(rawValue: HoYoServer.store.string(forKey: storageKey) ?? "") == nil else { return }
        select(guess())
    }

    static func guess(preferred: String? = Locale.preferredLanguages.first) -> AppLanguage {
        let language = Locale.Language(identifier: preferred ?? "en")
        guard language.languageCode == .chinese else { return .en }
        return language.maximalIdentifier.contains("Hant") ? .zhHant : .zhHans
    }

    var locale: Locale { Locale(identifier: rawValue) }

    // 语言自己的写法，不管当前界面是什么语言都能认出来。
    var nativeName: String {
        switch self {
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .en:     return "English"
        }
    }

    // 活动日历接口的 lang 参数。
    var calendarLang: String {
        switch self {
        case .zhHans: return "zh-cn"
        case .zhHant: return "zh-tw"
        case .en:     return "en"
        }
    }

    // 对应语言的 .lproj，供 String(localized:bundle:) 在 App 内切换语言。
    var bundle: Bundle { Self.bundles[self] ?? .main }

    private static let bundles: [AppLanguage: Bundle] = {
        var result: [AppLanguage: Bundle] = [:]
        for language in [AppLanguage.zhHans, .zhHant, .en] {
            if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                result[language] = bundle
            }
        }
        return result
    }()
}

extension Bundle {
    nonisolated static var appLanguage: Bundle { AppLanguage.current.bundle }
}
