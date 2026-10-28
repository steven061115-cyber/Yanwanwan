import SwiftUI

// 攻略视频搜索：国服用哔哩哔哩，海外用 YouTube。
enum GuideVideoSearch {
    static var isBilibili: Bool { HoYoServer.current.usesBilibili }

    static var title: String {
        isBilibili ? String(localized: "在哔哩哔哩搜索攻略", bundle: .appLanguage) : String(localized: "在 YouTube 搜索攻略", bundle: .appLanguage)
    }

    static var brandColor: Color {
        isBilibili ? Color(hex: "00A1D6") : Color(hex: "FF0033")
    }

    @ViewBuilder
    static var badge: some View {
        if isBilibili {
            Text("bili").font(.system(size: 12, weight: .black)).foregroundStyle(.white)
        } else {
            Image(systemName: "play.fill").font(.system(size: 18, weight: .black)).foregroundStyle(.white)
        }
    }

    // 国服优先唤起 B站 App，未安装时回退到网页搜索。YouTube 的网页链接会自动唤起已安装的 App。
    static func open(gameName: String, eventTitle: String, using openURL: OpenURLAction) {
        let suffix = isBilibili ? "攻略" : "guide"
        let keyword = "\(gameName) \(eventTitle) \(suffix)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard isBilibili else {
            if let url = URL(string: "https://www.youtube.com/results?search_query=\(keyword)") {
                openURL(url)
            }
            return
        }

        guard let appURL = URL(string: "bilibili://search?keyword=\(keyword)"),
              let webURL = URL(string: "https://search.bilibili.com/all?keyword=\(keyword)") else { return }
        openURL(appURL) { accepted in
            if !accepted { openURL(webURL) }
        }
    }
}
