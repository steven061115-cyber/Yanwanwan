import SwiftUI
import SwiftData

struct AIGameSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(PurchaseService.self) private var purchaseService
    @Query private var prefsQuery: [UserPreferences]
    @Query private var customGames: [CustomGame]

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
    @State private var webExtractorItem: WebExtractorTarget? = nil

    private struct WebExtractorTarget: Identifiable {
        let id  = UUID()
        let url: URL
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── 游戏信息 ──────────────────────────────────────────────
                Section {
                    HStack(spacing: 12) {
                        TextField("🎮", text: $gameEmoji)
                            .frame(width: 44)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .onChange(of: gameEmoji) { _, v in
                                if v.count > 2 { gameEmoji = String(v.prefix(2)) }
                            }

                        TextField("游戏名称", text: $gameName)
                            .onChange(of: gameName) { _, _ in
                                drafts      = []
                                hasSearched = false
                            }
                    }

                    HStack(spacing: 8) {
                        Text("卡片颜色")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        ForEach(CustomGamePalette.allCases, id: \.rawValue) { palette in
                            Circle()
                                .fill(palette.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().stroke(Color.hoyoDark, lineWidth: colorHex == palette.rawValue ? 2.5 : 0)
                                )
                                .onTapGesture { colorHex = palette.rawValue }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("游戏信息")
                }

                // ── B站公告链接 ───────────────────────────────────────────
                Section {
                    TextField("https://b23.tv/...", text: $articleURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    HStack(spacing: 4) {
                        Text("B站公告链接")
                        Button { showLinkGuide = true } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.hoyoPink)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("粘贴哔哩哔哩版本公告的分享链接（b23.tv/…），应用会用内置浏览器打开提取内容。")
                }

                // ── 打开公告按钮 ──────────────────────────────────────────
                Section {
                    Button {
                        Task { await openBilibiliPage() }
                    } label: {
                        HStack {
                            Spacer()
                            Label("打开 B站公告页面", systemImage: "tv.fill")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.hoyoPink)
                            Spacer()
                        }
                    }
                    .disabled(
                        gameName.trimmingCharacters(in: .whitespaces).isEmpty ||
                        articleURL.trimmingCharacters(in: .whitespaces).isEmpty ||
                        aiService.isSearching
                    )
                } footer: {
                    if let err = aiService.errorMessage {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                // ── 提取结果 ──────────────────────────────────────────────
                if hasSearched && !drafts.isEmpty {
                    Section {
                        ForEach($drafts) { $draft in
                            Toggle(isOn: $draft.isSelected) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(draft.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(draft.endDateShort)结束 · \(draft.category)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(Color.hoyoPink)
                        }
                    } header: {
                        Text("AI 提取结果（共 \(drafts.count) 条）")
                    } footer: {
                        Text("AI 结果仅供参考，请确认日期准确后再保存。取消勾选不需要的活动。")
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
            .scrollContentBackground(.hidden)
            .background(Color.hoyoBg)
            .sheet(isPresented: $showLinkGuide) { BilibiliLinkGuideSheet() }
            .sheet(isPresented: $showPremium) { PremiumView() }
            .alert("无法保存", isPresented: Binding(
                get: { saveLimitMessage != nil },
                set: { if !$0 { saveLimitMessage = nil } }
            )) {
                if !purchaseService.isPremium {
                    Button("升级会员") { showPremium = true }
                }
                Button("知道了", role: .cancel) {}
            } message: {
                Text(saveLimitMessage ?? "")
            }
            .sheet(item: $webExtractorItem) { item in
                WebExtractorSheet(url: item.url) { extractedText, finalURL in
                    let name = gameName.trimmingCharacters(in: .whitespaces)
                    Task {
                        hasSearched = false
                        drafts = await aiService.extractEvents(
                            from: extractedText,
                            gameName: name,
                            articleURL: finalURL,
                            entitlementTier: purchaseService.tier
                        )
                        hasSearched = true
                    }
                }
            }
            .navigationTitle("添加游戏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
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

    private func openBilibiliPage() async {
        let raw = articleURL.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let urlString = extractFirstURL(from: raw) ?? raw
        guard let url = URL(string: urlString) else {
            aiService.errorMessage = "无法解析链接，请检查格式"
            return
        }
        webExtractorItem = WebExtractorTarget(url: url)
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
            saveLimitMessage = "当前自定义游戏 \(currentCount)/\(maxCustomGames)，请先删除已有自定义游戏，或升级会员。"
            return
        }

        let game = CustomGame(name: name, emoji: gameEmoji.isEmpty ? "🎮" : gameEmoji, colorHex: colorHex)
        modelContext.insert(game)

        let selectedDrafts = drafts.filter(\.isSelected)
        game.replaceEvents(with: selectedDrafts, in: modelContext)
        try? modelContext.save()

        NotificationManager.shared.rescheduleAll()
        dismiss()
    }

    private func currentCustomGameCount() -> Int {
        customGames.count
    }
}
