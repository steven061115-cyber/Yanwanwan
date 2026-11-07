import SwiftUI
import SwiftData
import UserNotifications

enum ComplianceConfig {
    static let privacyVersion = "2026-11-03-v3"
    static let supportEmail = "ztyysls@gmail.com"
    static let aiModelName = "DeepSeek"

    static var supportEmailURL: URL? { URL(string: "mailto:\(supportEmail)") }
}

enum PrivacyConsent {
    static let acceptedVersionKey = "privacy.acceptedVersion"
    static let acceptedAtKey = "privacy.acceptedAt"
    static let aiConsentKey = "privacy.aiProcessingConsent.v1"

    static var isCurrentVersionAccepted: Bool {
        UserDefaults.standard.string(forKey: acceptedVersionKey) == ComplianceConfig.privacyVersion
    }

    static func acceptCurrentVersion() {
        UserDefaults.standard.set(ComplianceConfig.privacyVersion, forKey: acceptedVersionKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: acceptedAtKey)
    }

    static func withdraw() {
        UserDefaults.standard.removeObject(forKey: acceptedVersionKey)
        UserDefaults.standard.removeObject(forKey: acceptedAtKey)
        UserDefaults.standard.removeObject(forKey: aiConsentKey)
    }
}

struct PrivacyConsentView: View {
    let onAccept: () -> Void

    // 不同意 → 先解释一次，仍不同意则停在这里，不联网也不申请权限。
    private enum Step { case ask, explain, declined }
    @State private var step = Step.ask
    @State private var document: LegalDocument?

    var body: some View {
        ZStack {
            Color.hoyoBg.ignoresSafeArea()

            VStack(spacing: 16) {
                Image("WanwanHead")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)

                Text(title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.hoyoNavy)

                VStack(alignment: .leading, spacing: 10) {
                    Text(message)
                    if step != .declined {
                        HStack(spacing: 0) {
                            Text("详见")
                            Group {
                                Button("《隐私政策》") { document = .privacy }
                                Button("《服务条款》") { document = .terms }
                            }
                            .foregroundStyle(Color.hoyoPink)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color.hoyoNavy.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .leading)

                buttons
            }
            .padding(22)
            .background(Color.hoyoCardBg, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
            .frame(maxWidth: 360)
            .padding(.horizontal, 32)
            .animation(.easeOut(duration: 0.2), value: step)
        }
        .sheet(item: $document) { document in
            NavigationStack {
                LegalDocumentView(document: document)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") { self.document = nil }
                        }
                    }
            }
        }
    }

    private var title: String {
        switch step {
        case .ask: String(localized: "欢迎使用 GG Tracker", bundle: .appLanguage)
        case .explain: String(localized: "需要你的同意", bundle: .appLanguage)
        case .declined: String(localized: "你未同意隐私政策", bundle: .appLanguage)
        }
    }

    private var message: String {
        switch step {
        case .ask:
            String(localized: "活动、提醒等数据保存在本机；同意后才会联网获取游戏活动。只有你主动使用 AI 整理时，才会上传公告内容。", bundle: .appLanguage)
        case .explain:
            String(localized: "获取游戏活动需要联网，我们需要先征得你的同意。若不同意，App 将无法提供活动数据。", bundle: .appLanguage)
        case .declined:
            String(localized: "我们不会联网、生成安装标识或申请通知权限。你可以随时重新查看并同意。", bundle: .appLanguage)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        switch step {
        case .ask:
            consentButtons(secondary: String(localized: "不同意", bundle: .appLanguage)) { step = .explain }
        case .explain:
            consentButtons(secondary: String(localized: "仍不同意", bundle: .appLanguage)) { step = .declined }
        case .declined:
            primaryButton(String(localized: "重新查看", bundle: .appLanguage)) { step = .ask }
        }
    }

    private func consentButtons(secondary: String, onDecline: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button(action: onDecline) {
                Text(secondary)
                    .font(.headline)
                    .foregroundStyle(Color.hoyoNavy.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.hoyoBg, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            primaryButton(String(localized: "同意并继续", bundle: .appLanguage)) {
                PrivacyConsent.acceptCurrentVersion()
                onAccept()
            }
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.hoyoPink, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

enum LegalDocument: String, Identifiable {
    case privacy
    case terms
    case thirdParties

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: String(localized: "隐私政策", bundle: .appLanguage)
        case .terms: String(localized: "服务条款", bundle: .appLanguage)
        case .thirdParties: String(localized: "第三方信息共享清单", bundle: .appLanguage)
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(document.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.hoyoNavy)
                Text("版本：\(ComplianceConfig.privacyVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                switch document {
                case .privacy: privacyContent
                case .terms: termsContent
                case .thirdParties: thirdPartyContent
                }
            }
            .padding(20)
        }
        .background(Color.hoyoBg)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var privacyContent: some View {
        Group {
            legalSection(localized("一、运营者与联系"), localized("本 App 的开发者（即 App Store 页面显示的开发者）负责本 App 的个人信息处理。联系邮箱：\(ComplianceConfig.supportEmail)。你可以通过该渠道提出查阅、更正、删除、撤回同意或投诉请求。"))
            legalSection(localized("二、处理的信息"), localized("为提供活动提醒和 AI 整理功能，我们可能处理：随机安装标识、IP 地址、你主动提交的游戏名、公告链接与正文、App Store 交易凭证，以及设备本地保存的游戏、活动和通知设置。我们不进行跨 App 或跨网站追踪。"))
            legalSection(localized("三、处理目的与方式"), localized("随机安装标识和 IP 地址仅用于每日 AI 额度和基础限流，IP 地址只在服务器内存中临时使用、不写入数据库；公告内容仅在你主动发起 AI 整理时发送；交易凭证仅用于核验会员权益。本地活动数据默认保存在设备，启用 iCloud 时可能由 Apple 同步。"))
            legalSection(localized("四、第三方服务"), localized("活动数据接口用于获取公开活动时间；DeepSeek 用于整理你主动提交的公告；Apple 提供内购、iCloud 和通知系统。具体接收信息及用途见“第三方信息共享清单”。"))
            legalSection(localized("五、保存期限"), localized("安装标识对应的每日额度记录按提供服务和安全审计所需的最短期限保存。AI 共享结果缓存不保存用户身份映射，也不保存原始公告正文；本地数据保留至你删除 App 数据。"))
            legalSection(localized("六、数据存储"), localized("后端服务托管在 Railway 云平台，AI 整理请求会转发给 DeepSeek 处理。你的数据可能在你所在国家或地区以外的服务器上处理，我们会采取合理措施保护传输与存储安全。"))
            legalSection(localized("七、你的权利"), localized("你可以在“设置－隐私与合规－管理我的数据”中清除本地数据、删除服务器额度记录、重置安装标识或撤回同意。撤回同意后 App 将返回隐私确认页，不再启动联网服务。"))
            legalSection(localized("八、未成年人保护"), localized("本 App 不以未成年人为主要服务对象，也不要求提供真实身份信息。未成年人应在监护人指导下使用 AI 功能和购买服务。监护人可通过联系邮箱提出处理请求。"))
            legalSection(localized("九、安全与更新"), localized("我们采用 HTTPS、访问限制和最小化存储保护数据。政策发生实质变化时，App 会通过新的政策版本再次征求同意。"))
        }
    }

    private var termsContent: some View {
        Group {
            legalSection(localized("服务说明"), localized("本 App 用于个人整理游戏活动与提醒。活动数据和 AI 结果可能存在延迟或错误，请以游戏官方公告为准。"))
            legalSection(localized("会员与购买"), localized("数字权益由 Apple App Store 处理。订阅价格、周期、自动续订、取消及退款规则以购买页面和 Apple 规则为准。App 内购买同时受 Apple 标准许可协议（EULA）约束。"))
            legalSection(localized("使用规范"), localized("请勿批量滥用接口、绕过额度限制、提交违法或侵害他人权益的内容。"))
            legalSection(localized("知识产权与非官方声明"), localized("本 App 为非官方工具，与游戏厂商不存在隶属或授权关系。第三方名称和信息仅用于说明兼容对象，相关权利归原权利人所有。"))
        }
    }

    // Service names stay untranslated; only the descriptions follow the app language.
    private var thirdPartyContent: some View {
        Group {
            legalSection("DeepSeek", localized("接收：你主动提交的游戏名和公告正文。目的：从公告中整理活动名称和时间。"))
            legalSection("Apple", localized("接收：由 Apple 处理的购买、订阅、iCloud 与通知相关信息。目的：内购、权益恢复、系统同步和本地通知。"))
            legalSection(localized("活动数据接口"), localized("接收：所选游戏标识和语言参数，经由我们的后端转发。目的：获取公开游戏活动时间。"))
            legalSection("Railway", localized("接收：安装标识、IP 地址、AI 请求和交易核验凭证。目的：托管后端，用于额度控制、AI 整理和会员核验。"))
        }
    }

    private func localized(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: .appLanguage)
    }

    private func legalSection(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(Color.hoyoNavy)
            Text(text).font(.body).foregroundStyle(Color.hoyoNavy.opacity(0.72))
        }
    }
}

struct AIProcessingDisclosureView: View {
    let onAgree: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showDetails = false
    @State private var detent = PresentationDetent.height(300)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("使用 AI 整理公告", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(Color.hoyoNavy)

            Text("你提交的游戏名、公告链接和正文将发送至 \(ComplianceConfig.aiModelName) 整理。结果仅供参考，请以官方公告为准。")
                .font(.subheadline)
                .foregroundStyle(Color.hoyoNavy.opacity(0.72))

            Button {
                showDetails.toggle()
                detent = showDetails ? .large : .height(300)
            } label: {
                HStack(spacing: 4) {
                    Text(showDetails ? "收起详情" : "查看详情")
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.hoyoPink)
            }
            .buttonStyle(.plain)

            if showDetails {
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(String(localized: "同时发送", bundle: .appLanguage), String(localized: "随机安装标识与会员核验凭证，用于额度控制；不会上传你在 App 中创建的其他游戏或活动", bundle: .appLanguage))
                    detailRow(String(localized: "模型", bundle: .appLanguage), ComplianceConfig.aiModelName)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.hoyoBg, in: RoundedRectangle(cornerRadius: 14))
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Text("暂不使用")
                        .font(.headline)
                        .foregroundStyle(Color.hoyoNavy.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.hoyoBg, in: RoundedRectangle(cornerRadius: 14))
                }
                Button {
                    UserDefaults.standard.set(true, forKey: PrivacyConsent.aiConsentKey)
                    dismiss()
                    onAgree()
                } label: {
                    Text("同意并提取")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.hoyoPink, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 12)
        .background(Color.hoyoCardBg)
        .presentationDetents([.height(300), .large], selection: $detent)
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
        .animation(.easeOut(duration: 0.2), value: showDetails)
        .onChange(of: detent) { _, newValue in
            // Dragged back down to the compact height: fold the details so nothing gets clipped.
            if newValue != .large { showDetails = false }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.footnote).foregroundStyle(Color.hoyoNavy)
        }
    }
}

struct ComplianceCenterView: View {
    var body: some View {
        List {
            Section("政策与清单") {
                NavigationLink("隐私政策") { LegalDocumentView(document: .privacy) }
                NavigationLink("服务条款") { LegalDocumentView(document: .terms) }
                NavigationLink("第三方信息共享清单") { LegalDocumentView(document: .thirdParties) }
            }

            Section("联系开发者") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("联系邮箱").font(.caption).foregroundStyle(.secondary)
                    if let url = ComplianceConfig.supportEmailURL {
                        Link(ComplianceConfig.supportEmail, destination: url)
                            .foregroundStyle(Color.hoyoPink)
                    } else {
                        Text(ComplianceConfig.supportEmail)
                    }
                }
            }

            Section {
                NavigationLink("管理我的数据") { DataManagementView() }
            } footer: {
                Text("可清除本地数据、删除服务器额度记录、重置安装标识或撤回隐私同意。")
            }
        }
        .navigationTitle("隐私与合规")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var customGames: [CustomGame]
    @State private var confirmation: Action?
    @State private var isWorking = false
    @State private var resultMessage: String?

    private enum Action: String, Identifiable {
        case local, server, all, withdraw
        var id: String { rawValue }
    }

    var body: some View {
        List {
            Section("设备数据") {
                Button("清除本地活动与设置", role: .destructive) { confirmation = .local }
                Button("重置 AI 安装标识", role: .destructive) { confirmation = .server }
            }

            Section("全部数据") {
                Button("删除本地与服务器数据", role: .destructive) { confirmation = .all }
                Button("撤回隐私同意", role: .destructive) { confirmation = .withdraw }
            }

            if isWorking {
                Section { HStack { ProgressView(); Text("正在处理…") } }
            }
        }
        .navigationTitle("管理我的数据")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("此操作不可撤销", isPresented: Binding(
            get: { confirmation != nil },
            set: { if !$0 { confirmation = nil } }
        )) {
            if let action = confirmation {
                Button(actionTitle(action), role: .destructive) {
                    Task { await perform(action) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let action = confirmation {
                Text(actionMessage(action))
            }
        }
        .alert("处理结果", isPresented: Binding(
            get: { resultMessage != nil },
            set: { if !$0 { resultMessage = nil } }
        )) {
            Button("知道了") {}
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private func perform(_ action: Action) async {
        isWorking = true
        defer { isWorking = false }
        do {
            switch action {
            case .local:
                try clearLocalData()
                resultMessage = String(localized: "本地活动、设置、通知和小组件数据已清除。", bundle: .appLanguage)
            case .server:
                try await deleteServerData()
                InstallID.reset()
                resultMessage = String(localized: "服务器额度记录已删除，安装标识已重置。", bundle: .appLanguage)
            case .all:
                try await deleteServerData()
                try clearLocalData()
                InstallID.reset()
                resultMessage = String(localized: "本地数据和服务器额度记录已删除。", bundle: .appLanguage)
            case .withdraw:
                PrivacyConsent.withdraw()
                resultMessage = String(localized: "已撤回同意。请重新启动 App；在再次同意前不会启动联网服务。", bundle: .appLanguage)
            }
        } catch {
            resultMessage = String(localized: "操作未全部完成：\(error.localizedDescription)", bundle: .appLanguage)
        }
    }

    private func clearLocalData() throws {
        for game in customGames { modelContext.delete(game) }
        for prefs in preferences { modelContext.delete(prefs) }
        try modelContext.save()
        UserDefaults.standard.removeObject(forKey: "onboardingDone")
        UserDefaults.standard.removeObject(forKey: PrivacyConsent.aiConsentKey)
        SharedWidgetData.clear()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    private func deleteServerData() async throws {
        guard let url = APIConfig.dataDeletionURL else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(InstallID.current, forHTTPHeaderField: "X-Install-ID")
        request.timeoutInterval = 20
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func actionTitle(_ action: Action) -> String {
        switch action {
        case .local: String(localized: "确认清除本地数据", bundle: .appLanguage)
        case .server: String(localized: "确认删除并重置", bundle: .appLanguage)
        case .all: String(localized: "确认删除全部数据", bundle: .appLanguage)
        case .withdraw: String(localized: "确认撤回同意", bundle: .appLanguage)
        }
    }

    private func actionMessage(_ action: Action) -> String {
        switch action {
        case .local: String(localized: "会删除设备内的游戏、活动、缓存、设置和通知。", bundle: .appLanguage)
        case .server: String(localized: "会删除当前安装标识对应的服务器额度记录，并生成新的安装标识。", bundle: .appLanguage)
        case .all: String(localized: "会同时删除设备数据和当前安装标识对应的服务器记录。", bundle: .appLanguage)
        case .withdraw: String(localized: "撤回后需要重新同意隐私政策才能继续使用联网功能。", bundle: .appLanguage)
        }
    }
}
