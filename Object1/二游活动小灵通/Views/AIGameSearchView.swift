import SwiftUI
import SwiftData

// 国际服官网公告页。官网只有英文和一种中文版本，按 App 语言选一个。
struct OfficialNewsPage {
    let english: String
    let chinese: String
    // 英文官网上版本更新公告的真实标题，引导用户找对公告；中文官网的标题不同，所以只在英文界面显示。
    let englishNoticeExample: String

    var forCurrentLanguage: String {
        AppLanguage.current == .en ? english : chinese
    }

    var noticeExampleForCurrentLanguage: String? {
        AppLanguage.current == .en ? englishNoticeExample : nil
    }
}

// 海外公告链接的提示：说明要选版本更新公告，英文界面附上该游戏的真实标题。
func overseasNoticeLinkHint(for page: OfficialNewsPage?) -> String {
    let hint = String(localized: "粘贴版本更新公告（Patch Notes / Version Update Notes）的链接，它会用文字列出每个活动的时间。不要用卡池公告、新闻列表页，或全是图片的活动一览。粘贴后用内置浏览器提取内容。", bundle: .appLanguage)
    guard let example = page?.noticeExampleForCurrentLanguage else { return hint }
    return hint + "\n" + String(localized: "例如：\(example)", bundle: .appLanguage)
}

enum OverseasOfficialNews {
    // 键是游戏名的中文原文，也是 Localizable 里的翻译键。
    static let pages: [String: OfficialNewsPage] = [
        "鸣潮": .init(english: "https://wutheringwaves.kurogames.com/en/main/news",
                    chinese: "https://wutheringwaves.kurogames.com/zh-tw/main/news",
                    englishNoticeExample: "Patch Notes for Wuthering Waves Version 3.7"),
        "终末地": .init(english: "https://endfield.gryphline.com/en-us#notice",
                     chinese: "https://endfield.gryphline.com/zh-tw#notice",
                     englishNoticeExample: "[Sanctuary of Ink] Version Update Notes"),
        "异环": .init(english: "https://nte.perfectworld.com/en/article/news/index.html",
                    chinese: "https://nte.perfectworld.com/cn/article/news/index.html",
                    englishNoticeExample: "Ver. 1.4 Patch Notes"),
    ]

    // 自定义游戏的名字是添加时的语言写的，三种语言的译名都认。
    static func page(forGameName name: String) -> OfficialNewsPage? {
        for (key, page) in pages {
            let names = AppLanguage.allCases.map { String(localized: String.LocalizationValue(key), bundle: $0.bundle) }
            if key == name || names.contains(name) { return page }
        }
        return nil
    }
}

struct AIGameSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.openURL)      private var openURL
    @Environment(PurchaseService.self) private var purchaseService
    @Query private var prefsQuery: [UserPreferences]
    @Query private var customGames: [CustomGame]

    // 国服显示全部推荐游戏，走 B站；其他服务器只显示有国际服官网公告页的几款。
    private let allRecommendedBilibiliSpaces: [RecommendedBilibiliSpace] = [
        .init(name: String(localized: "鸣潮", bundle: .appLanguage), emoji: "🌊", colorHex: CustomGamePalette.mint.rawValue, url: "https://b23.tv/Wdixy1J",
              overseasNews: OverseasOfficialNews.pages["鸣潮"]),
        .init(name: String(localized: "战双帕弥什", bundle: .appLanguage), emoji: "⚔️", colorHex: CustomGamePalette.purple.rawValue, url: "https://b23.tv/AZBFXO0"),
        .init(name: String(localized: "终末地", bundle: .appLanguage), emoji: "🧭", colorHex: CustomGamePalette.yellow.rawValue, url: "https://b23.tv/LwktPtX",
              overseasNews: OverseasOfficialNews.pages["终末地"]),
        .init(name: String(localized: "异环", bundle: .appLanguage), emoji: "🔮", colorHex: CustomGamePalette.violet.rawValue, url: "https://b23.tv/4zzUBvF",
              overseasNews: OverseasOfficialNews.pages["异环"]),
        .init(name: String(localized: "幻塔", bundle: .appLanguage), emoji: "🗼", colorHex: CustomGamePalette.pink.rawValue, url: "https://b23.tv/Akp3x70"),
        .init(name: String(localized: "洛克王国世界", bundle: .appLanguage), emoji: "👑", colorHex: CustomGamePalette.yellow.rawValue, url: "https://b23.tv/StJcE8K"),
        .init(name: String(localized: "少女前线2追放", bundle: .appLanguage), emoji: "🎯", colorHex: CustomGamePalette.violet.rawValue, url: "https://b23.tv/aNZgNA8"),
        .init(name: String(localized: "碧蓝航线", bundle: .appLanguage), emoji: "⚓", colorHex: CustomGamePalette.mint.rawValue, url: "https://b23.tv/vW1KLKz"),
        .init(name: String(localized: "尘白禁区", bundle: .appLanguage), emoji: "❄️", colorHex: CustomGamePalette.purple.rawValue, url: "https://b23.tv/0d6PbvL"),
        .init(name: String(localized: "碧蓝档案", bundle: .appLanguage), emoji: "📘", colorHex: CustomGamePalette.violet.rawValue, url: "https://b23.tv/DQmnvde")
    ]

    private var recommendedBilibiliSpaces: [RecommendedBilibiliSpace] {
        HoYoServer.current == .china
            ? allRecommendedBilibiliSpaces
            : allRecommendedBilibiliSpaces.filter { $0.overseasNews != nil }
    }

    private enum AddGameStep {
        case chooseGame
        case pasteLink
    }

    @State private var currentStep      = AddGameStep.chooseGame
    @State private var aiService        = AIGameService()
    @State private var gameName         = ""
    @State private var gameEmoji        = "🎮"
    @State private var colorHex         = CustomGamePalette.violet.rawValue
    @State private var articleURL       = ""
    @State private var drafts:          [AIEventDraft] = []
    @State private var hasSearched      = false
    @State private var showLinkGuide    = false
    @State private var showPremium      = false
    @State private var saveLimitMessage: String? = nil
    @State private var saveErrorMessage: String? = nil
    @State private var pendingRecommendedSpace: RecommendedBilibiliSpace? = nil
    // 说明页完全关闭后再打开，避免和内置浏览器的弹出冲突。
    @State private var spaceToOpenAfterGuide: RecommendedBilibiliSpace? = nil
    @State private var webExtractorItem: WebExtractorTarget? = nil
    @State private var showAIDisclosure = false
    @State private var pendingExtractionURL: URL? = nil

    private struct WebExtractorTarget: Identifiable {
        let id  = UUID()
        let url: URL
    }

    private struct RecommendedBilibiliSpace: Identifiable {
        let name: String
        let emoji: String
        let colorHex: String
        let url: String
        // 国际服官网公告页；海外服务器下用默认浏览器打开，用户找到具体公告后复制链接回来粘贴。
        var overseasNews: OfficialNewsPage? = nil

        var id: String { name }
    }

    private struct BilibiliOfficialSpaceGuideSheet: View {
        let space: RecommendedBilibiliSpace
        let onOpen: () -> Void

        private var usesBilibili: Bool { HoYoServer.current.usesBilibili }

        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                List {
                    Section {
                        HStack(spacing: 12) {
                            Text(space.emoji)
                                .font(.largeTitle)
                                .frame(width: 48, height: 48)
                                .background(Color.hoyoPink.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(space.name)
                                    .font(.headline)
                                    .foregroundStyle(Color.hoyoNavy)
                                Text(usesBilibili ? String(localized: "B站官方空间", bundle: .appLanguage) : String(localized: "国际服官网", bundle: .appLanguage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        if usesBilibili {
                            bilibiliSteps
                        } else {
                            officialSiteSteps
                        }
                    } header: {
                        Label("操作步骤", systemImage: "list.number")
                            .textCase(nil)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Section {
                        Button {
                            onOpen()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label(usesBilibili ? String(localized: "去 B站", bundle: .appLanguage) : String(localized: "打开官网公告", bundle: .appLanguage),
                                      systemImage: "arrow.up.forward.app")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .foregroundStyle(Color.hoyoPink)
                    } footer: {
                        Text(usesBilibili
                             ? String(localized: "从 B站复制公告链接后回到本页，使用「粘贴」按钮填入公告链接。", bundle: .appLanguage)
                             : String(localized: "从官网复制公告链接后回到本页，使用「粘贴」按钮填入公告链接。", bundle: .appLanguage))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.hoyoBg)
                .navigationTitle(usesBilibili ? String(localized: "去 B站找公告", bundle: .appLanguage) : String(localized: "去官网找公告", bundle: .appLanguage))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { dismiss() }
                    }
                }
            }
        }

        @ViewBuilder
        private var bilibiliSteps: some View {
            guideStep(number: "1", title: String(localized: "打开官方空间", bundle: .appLanguage),
                      detail: String(localized: "点下方按钮跳转到手机上的 B站 App。", bundle: .appLanguage))
            guideStep(number: "2", title: String(localized: "寻找图文，选择最新版本公告", bundle: .appLanguage),
                      detail: String(localized: "在官方空间里进入「图文」内容，选择最新版本的综合公告，不要选单个活动介绍。", bundle: .appLanguage))
            guideStep(number: "3", title: String(localized: "分享并复制链接", bundle: .appLanguage),
                      detail: String(localized: "在公告页点分享，复制 b23.tv 短链，回到本页点「粘贴」。", bundle: .appLanguage))
        }

        private var officialSiteStep2Detail: String {
            let detail = String(localized: "选标题含「更新公告」「Patch Notes」或「Version Update Notes」的那篇，里面会用文字列出每个活动的时间。不要选卡池公告（Convene、Headhunting 等），也不要选全是图片的活动一览，AI 读不了图片。", bundle: .appLanguage)
            guard let example = space.overseasNews?.noticeExampleForCurrentLanguage else { return detail }
            return detail + "\n" + String(localized: "例如：\(example)", bundle: .appLanguage)
        }

        @ViewBuilder
        private var officialSiteSteps: some View {
            guideStep(number: "1", title: String(localized: "打开官网公告页", bundle: .appLanguage),
                      detail: String(localized: "点下方按钮，在浏览器里打开国际服官网的公告页。", bundle: .appLanguage))
            guideStep(number: "2", title: String(localized: "点开版本更新公告", bundle: .appLanguage),
                      detail: officialSiteStep2Detail)
            guideStep(number: "3", title: String(localized: "复制链接", bundle: .appLanguage),
                      detail: String(localized: "复制这篇公告的网址，回到本页点「粘贴」。", bundle: .appLanguage))
        }

        @ViewBuilder
        private func guideStep(number: String, title: String, detail: String) -> some View {
            HStack(alignment: .top, spacing: 12) {
                Text(number)
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.hoyoPink, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if currentStep == .chooseGame {
                    chooseGameSections
                } else {
                    pasteLinkSections
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.hoyoBg)
            .sheet(isPresented: $showLinkGuide) { BilibiliLinkGuideSheet() }
            .sheet(item: $pendingRecommendedSpace, onDismiss: {
                guard let space = spaceToOpenAfterGuide else { return }
                spaceToOpenAfterGuide = nil
                openRecommendedSpace(space)
            }) { space in
                BilibiliOfficialSpaceGuideSheet(space: space) {
                    spaceToOpenAfterGuide = space
                }
            }
            .sheet(isPresented: $showPremium) { PremiumView() }
            .sheet(isPresented: $showAIDisclosure) {
                AIProcessingDisclosureView {
                    if let url = pendingExtractionURL {
                        webExtractorItem = WebExtractorTarget(url: url)
                    }
                    pendingExtractionURL = nil
                }
            }
            .alert(purchaseService.tier.extractionLimitTitle, isPresented: Binding(
                get: { aiService.quotaLimitMessage != nil },
                set: { if !$0 { aiService.quotaLimitMessage = nil } }
            )) {
                if purchaseService.tier == .free {
                    Button("升级会员") {
                        aiService.quotaLimitMessage = nil
                        showPremium = true
                    }
                }
                Button("知道了", role: .cancel) {}
            } message: {
                Text(aiService.quotaLimitMessage ?? "")
            }
            .alert("自定义游戏已达上限", isPresented: Binding(
                get: { saveLimitMessage != nil },
                set: { if !$0 { saveLimitMessage = nil } }
            )) {
                if !purchaseService.isPremium {
                    Button("升级会员") {
                        saveLimitMessage = nil
                        showPremium = true
                    }
                }
                Button("知道了", role: .cancel) {}
            } message: {
                Text(saveLimitMessage ?? "")
            }
            .alert("保存失败", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
            .sheet(item: $webExtractorItem) { item in
                WebExtractorSheet(url: item.url) { extractedText, finalURL in
                    let name = gameName.trimmingCharacters(in: .whitespaces)
                    Task {
                        hasSearched = false
                        let entitlementProof = await purchaseService.currentEntitlementJWS()
                        drafts = await aiService.extractEvents(
                            from: extractedText,
                            gameName: name,
                            articleURL: finalURL,
                            entitlementTier: purchaseService.tier,
                            appStoreTransactionJWS: entitlementProof
                        )
                        hasSearched = true
                    }
                }
            }
            .navigationTitle(currentStep == .chooseGame ? "选择游戏" : "提取公告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep == .chooseGame {
                        Button("取消") { dismiss() }
                    } else {
                        Button("重选") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep = .chooseGame
                            }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if currentStep == .pasteLink {
                        Button("保存") { save() }
                            .fontWeight(.semibold)
                            .disabled(
                                gameName.trimmingCharacters(in: .whitespaces).isEmpty ||
                                drafts.filter(\.isSelected).isEmpty
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var chooseGameSections: some View {
        Section {
            ForEach(recommendedBilibiliSpaces) { space in
                Button {
                    selectRecommendedSpace(space)
                } label: {
                    HStack(spacing: 12) {
                        Text(space.emoji)
                            .font(.title3)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(space.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.hoyoNavy)
                            Text("B站官方空间")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("选择游戏")
        } footer: {
            Text("先选游戏，再按引导打开对应的 B站官方空间。")
        }
    }

    @ViewBuilder
    private var pasteLinkSections: some View {
        Section {
            HStack(spacing: 12) {
                Text(gameEmoji)
                    .font(.title2)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: colorHex).opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(gameName.isEmpty ? String(localized: "未选择游戏", bundle: .appLanguage) : gameName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.hoyoNavy)
                    Text("已跳转 B站，请粘贴具体版本公告链接")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        } header: {
            Text("当前游戏")
        }

        Section {
            HStack(spacing: 10) {
                TextField(HoYoServer.current.usesBilibili ? "https://b23.tv/..." : "https://...", text: $articleURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button {
                    pasteArticleURL()
                } label: {
                    Label("粘贴", systemImage: "doc.on.clipboard")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.hoyoPink)
            }
        } header: {
            if HoYoServer.current.usesBilibili {
                HStack(spacing: 4) {
                    Text("B站公告链接")
                    Button { showLinkGuide = true } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Color.hoyoPink)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("公告链接")
            }
        } footer: {
            Text(HoYoServer.current.usesBilibili
                 ? String(localized: "粘贴从 B站 App 里复制出来的具体版本公告分享链接（b23.tv/…），再用内置浏览器提取内容。", bundle: .appLanguage)
                 : overseasNoticeLinkHint(for: OverseasOfficialNews.page(forGameName: gameName)))
        }

        Section {
            Button {
                Task { await openArticlePage() }
            } label: {
                HStack {
                    Spacer()
                    Label(HoYoServer.current.usesBilibili ? String(localized: "打开 B站公告页面", bundle: .appLanguage) : String(localized: "打开公告页面", bundle: .appLanguage),
                          systemImage: HoYoServer.current.usesBilibili ? "tv.fill" : "safari.fill")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.hoyoPink)
                    Spacer()
                }
            }
            .disabled(
                gameName.trimmingCharacters(in: .whitespaces).isEmpty ||
                articleURL.trimmingCharacters(in: .whitespaces).isEmpty ||
                aiService.isSearching ||
                aiService.isCheckingQuota
            )
        } footer: {
            if let err = aiService.errorMessage {
                Label(err, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }

        if hasSearched && !drafts.isEmpty {
            Section {
                ForEach($drafts) { $draft in
                    Toggle(isOn: $draft.isSelected) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(draft.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(draft.endDateShort)结束 · \(localizedEventCategory(draft.category))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color.hoyoPink)
                }
            } header: {
                Label("AI 整理结果（共 \(drafts.count) 条）", systemImage: "sparkles")
            } footer: {
                Text("以上内容由 \(ComplianceConfig.aiModelName) 整理，仅供参考。请对照游戏官方公告核对名称和日期后再保存。")
            }
        } else if hasSearched && !aiService.isSearching && aiService.errorMessage == nil {
            Section {
                ContentUnavailableView {
                    Label("未找到活动", systemImage: "magnifyingglass")
                } description: {
                    Text("请确认页面内容是否为版本公告，或该游戏当前无限时活动。")
                }
                .listRowBackground(Color.clear)
            }
        }
    }

    private func openArticlePage() async {
        let raw = articleURL.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let urlString = extractFirstURL(from: raw) ?? raw
        guard let url = URL(string: urlString) else {
            aiService.errorMessage = String(localized: "无法解析链接，请检查格式", bundle: .appLanguage)
            return
        }
        let entitlementProof = await purchaseService.currentEntitlementJWS()
        guard await aiService.canStartExtraction(
            entitlementTier: purchaseService.tier,
            appStoreTransactionJWS: entitlementProof
        ) else { return }
        if UserDefaults.standard.bool(forKey: PrivacyConsent.aiConsentKey) {
            webExtractorItem = WebExtractorTarget(url: url)
        } else {
            pendingExtractionURL = url
            showAIDisclosure = true
        }
    }

    private func selectRecommendedSpace(_ space: RecommendedBilibiliSpace) {
        gameName = space.name
        gameEmoji = space.emoji
        colorHex = space.colorHex
        articleURL = ""
        drafts = []
        hasSearched = false
        aiService.errorMessage = nil
        aiService.quotaLimitMessage = nil
        pendingRecommendedSpace = space
    }

    private func openRecommendedSpace(_ space: RecommendedBilibiliSpace) {
        pendingRecommendedSpace = nil
        currentStep = .pasteLink

        // 海外：用默认浏览器打开国际服官网公告页，用户找到具体公告后复制链接回来粘贴。
        if !HoYoServer.current.usesBilibili, let news = space.overseasNews {
            guard let url = URL(string: news.forCurrentLanguage) else {
                aiService.errorMessage = String(localized: "无法打开 \(space.name) 的官网", bundle: .appLanguage)
                return
            }
            openURL(url)
            return
        }

        guard let url = URL(string: space.url) else {
            aiService.errorMessage = String(localized: "无法打开 \(space.name) 的 B站主页", bundle: .appLanguage)
            return
        }
        openURL(url)
    }

    private func pasteArticleURL() {
        let pasted = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !pasted.isEmpty else {
            aiService.errorMessage = String(localized: "剪贴板里没有可粘贴的公告链接", bundle: .appLanguage)
            return
        }

        articleURL = extractFirstURL(from: pasted) ?? pasted
        drafts = []
        hasSearched = false
        aiService.errorMessage = nil
        aiService.quotaLimitMessage = nil
    }

    private func extractFirstURL(from text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let range   = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        return matches.first {
            guard let scheme = $0.url?.scheme?.lowercased() else { return false }
            return scheme == "https" || scheme == "http"
        }?.url?.absoluteString
    }

    private func save() {
        let name = gameName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let currentCount = currentCustomGameCount()
        let maxCustomGames = purchaseService.tier.maxCustomGames
        guard currentCount < maxCustomGames else {
            saveLimitMessage = purchaseService.tier.customGameLimitMessage(currentCount: currentCount)
            return
        }

        let game = CustomGame(name: name, emoji: gameEmoji.isEmpty ? "🎮" : gameEmoji, colorHex: colorHex)
        modelContext.insert(game)

        let selectedDrafts = drafts.filter(\.isSelected)
        game.replaceEvents(with: selectedDrafts, in: modelContext)
        do {
            try modelContext.save()
            saveErrorMessage = nil
            NotificationManager.shared.rescheduleAll()
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = String(localized: "保存失败：\(error.localizedDescription)", bundle: .appLanguage)
        }
    }

    private func currentCustomGameCount() -> Int {
        customGames.count
    }
}
