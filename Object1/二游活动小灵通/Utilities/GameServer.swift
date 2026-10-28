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

    // 覆盖的地区，帮用户判断自己在哪个服。亚服的服务器时间统一是 UTC+8，日本、韩国也一样。
    var regions: String { regions(in: .current) }

    func regions(in language: AppLanguage) -> String {
        switch self {
        case .china:   return String(localized: "中国大陆", bundle: language.bundle)
        case .america: return String(localized: "北美、南美", bundle: language.bundle)
        case .europe:  return String(localized: "欧洲、中东、非洲", bundle: language.bundle)
        case .asia:    return String(localized: "日本、韩国、东南亚、港澳台", bundle: language.bundle)
        }
    }

    var utcOffsetLabel: String {
        utcOffsetHours >= 0 ? "UTC+\(utcOffsetHours)" : "UTC\(utcOffsetHours)"
    }

    // 默认界面语言。日文、韩文没有对应的服务器，只能在设置里手动选。
    var language: AppLanguage {
        switch self {
        case .china:            return .zhHans
        case .asia:             return .zhHant
        case .america, .europe: return .en
        }
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

// App 界面语言：默认跟随所选服务器，也可以在设置里单独指定。不跟随系统语言。
nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case en
    case ja
    case ko

    var id: String { rawValue }

    // 用户手动指定的语言；没有值表示跟随服务器。
    // 换了新键名：旧版"首次启动按系统语言自动保存"的值不能当成用户的手动选择。
    static let storageKey = "appLanguageOverride"

    static var override: AppLanguage? {
        HoYoServer.store.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:))
    }

    static var current: AppLanguage { override ?? HoYoServer.current.language }

    var locale: Locale { Locale(identifier: rawValue) }

    // 语言自己的写法，不管当前界面是什么语言都能认出来。
    var nativeName: String {
        switch self {
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .en:     return "English"
        case .ja:     return "日本語"
        case .ko:     return "한국어"
        }
    }

    // 活动日历接口的 lang 参数。
    var calendarLang: String {
        switch self {
        case .zhHans: return "zh-cn"
        case .zhHant: return "zh-tw"
        case .en:     return "en"
        case .ja:     return "ja"
        case .ko:     return "ko"
        }
    }

    // 对应语言的 .lproj，供 String(localized:bundle:) 在 App 内切换语言。
    var bundle: Bundle { Self.bundles[self] ?? .main }

    private static let bundles: [AppLanguage: Bundle] = {
        var result: [AppLanguage: Bundle] = [:]
        for language in AppLanguage.allCases {
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
