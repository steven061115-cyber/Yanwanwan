import Foundation
import Observation

// Pipeline: WKWebView 提取页面正文 → 后端调用 DeepSeek → App 确认保存

@MainActor
@Observable
final class AIGameService {
    var isSearching   = false
    var errorMessage: String? = nil

    // MARK: - Entry point

    func extractEvents(from text: String, gameName: String, articleURL: URL?, entitlementTier: EntitlementTier) async -> [AIEventDraft] {
        guard APIConfig.isAIBackendConfigured, APIConfig.aiExtractorURL != nil else {
            errorMessage = "请先部署 AI 后端，并在 APIConfig.swift 填入后端地址"
            return []
        }

        isSearching  = true
        errorMessage = nil
        defer { isSearching = false }

        let drafts = await backendExtract(
            searchText: text,
            gameName: gameName,
            articleURL: articleURL,
            entitlementTier: entitlementTier
        )
        if drafts.isEmpty && errorMessage == nil {
            errorMessage = "小的没找到游戏内活动，请确认页面内容是否为版本公告"
        }
        return drafts
    }

    // MARK: - Backend JSON extraction

    private func backendExtract(searchText: String, gameName: String, articleURL: URL?, entitlementTier: EntitlementTier) async -> [AIEventDraft] {
        let bjTZ = TimeZone(identifier: "Asia/Shanghai")!
        var cal = Calendar.current
        cal.timeZone = bjTZ

        let df = DateFormatter()
        df.timeZone = bjTZ
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm"

        let dfDateOnly = DateFormatter()
        dfDateOnly.timeZone = bjTZ
        dfDateOnly.locale = Locale(identifier: "en_US_POSIX")
        dfDateOnly.dateFormat = "yyyy-MM-dd"

        guard let url = APIConfig.aiExtractorURL,
              let bodyData = try? JSONEncoder().encode(ExtractionRequest(
                gameName: gameName,
                articleURL: articleURL?.absoluteString,
                text: searchText
              )) else {
            errorMessage = "AI 后端请求构建失败"
            return []
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(InstallID.current, forHTTPHeaderField: "X-Install-ID")
        req.setValue(entitlementTier.backendHeaderValue, forHTTPHeaderField: "X-Entitlement-Tier")
        req.httpBody        = bodyData
        req.timeoutInterval = 120

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let apiError = try? JSONDecoder().decode(ExtractionErrorResponse.self, from: data)
                let message = apiError?.message ?? String(data: data, encoding: .utf8) ?? ""
                errorMessage = "AI 后端错误（\(http.statusCode)）：\(message.prefix(120))"
                return []
            }

            guard let wrapper = try? JSONDecoder().decode(ExtractionResponse.self, from: data) else {
                errorMessage = "提取结果格式异常，请重试"
                return []
            }

            func parseDate(_ s: String) -> Date? {
                df.date(from: s) ?? dfDateOnly.date(from: s)
            }

            let todayStart = cal.startOfDay(for: Date())
            return wrapper.events.compactMap { r in
                guard let end = parseDate(r.endDate), end > todayStart else { return nil }
                let start = parseDate(r.startDate) ?? Date()
                return AIEventDraft(
                    title:     r.title,
                    startDate: start,
                    endDate:   end,
                    category:  r.category ?? "活动"
                )
            }
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    errorMessage = "请求超时：AI 处理长公告可能需要更久，请确认后端仍在运行后重试。"
                case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
                    errorMessage = "AI 后端连接失败：请确认后端已启动，且手机和 Mac 在同一 Wi-Fi。"
                case .notConnectedToInternet:
                    errorMessage = "网络不可用：请检查当前网络连接。"
                default:
                    errorMessage = "网络请求失败：\(urlError.localizedDescription)"
                }
            } else {
                errorMessage = "提取失败：\(error.localizedDescription)"
            }
            return []
        }
    }

    // MARK: - Codable models

    private struct ExtractionRequest: Encodable {
        let gameName: String
        let articleURL: String?
        let text: String
    }

    private struct ExtractionResponse: Decodable {
        let events: [RawEvent]
    }

    private struct ExtractionErrorResponse: Decodable {
        let message: String?
    }

    private struct RawEvent: Decodable {
        let title:     String
        let startDate: String
        let endDate:   String
        let category:  String?
    }
}
