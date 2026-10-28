import Foundation
import Observation

// Pipeline: WKWebView 提取页面正文 → 后端调用 DeepSeek → App 确认保存

@MainActor
@Observable
final class AIGameService {
    var isSearching   = false
    var isCheckingQuota = false
    var errorMessage: String? = nil
    var quotaLimitMessage: String? = nil

    // MARK: - Entry point

    func canStartExtraction(entitlementTier: EntitlementTier, appStoreTransactionJWS: String? = nil) async -> Bool {
        guard APIConfig.isAIBackendConfigured, let url = APIConfig.quotaURL else {
            errorMessage = String(localized: "请先部署提取后端，并在 APIConfig.swift 填入后端地址", bundle: .appLanguage)
            return false
        }

        isCheckingQuota = true
        errorMessage = nil
        quotaLimitMessage = nil
        defer { isCheckingQuota = false }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        applyBackendAuthHeaders(to: &req, appStoreTransactionJWS: appStoreTransactionJWS)
        req.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let apiError = try? JSONDecoder().decode(ExtractionErrorResponse.self, from: data)
                let message = apiError?.message ?? String(data: data, encoding: .utf8) ?? ""
                errorMessage = String(localized: "提取后端错误（\(http.statusCode)）：\(message.prefix(120))", bundle: .appLanguage)
                return false
            }

            guard let quota = try? JSONDecoder().decode(QuotaResponse.self, from: data) else {
                errorMessage = String(localized: "提取次数状态异常，请重试", bundle: .appLanguage)
                return false
            }

            if quota.canExtract {
                return true
            }

            quotaLimitMessage = quota.message ?? entitlementTier.extractionLimitMessage
            return false
        } catch {
            if let urlError = error as? URLError {
                errorMessage = String(localized: "提取次数检查失败：\(urlError.localizedDescription)", bundle: .appLanguage)
            } else {
                errorMessage = String(localized: "提取次数检查失败：\(error.localizedDescription)", bundle: .appLanguage)
            }
            return false
        }
    }

    func extractEvents(
        from text: String,
        gameName: String,
        articleURL: URL?,
        entitlementTier: EntitlementTier,
        appStoreTransactionJWS: String? = nil
    ) async -> [AIEventDraft] {
        guard APIConfig.isAIBackendConfigured, APIConfig.aiExtractorURL != nil else {
            errorMessage = String(localized: "请先部署提取后端，并在 APIConfig.swift 填入后端地址", bundle: .appLanguage)
            return []
        }

        isSearching  = true
        errorMessage = nil
        quotaLimitMessage = nil
        defer { isSearching = false }

        let drafts = await backendExtract(
            searchText: text,
            gameName: gameName,
            articleURL: articleURL,
            entitlementTier: entitlementTier,
            appStoreTransactionJWS: appStoreTransactionJWS
        )
        if drafts.isEmpty && errorMessage == nil && quotaLimitMessage == nil {
            errorMessage = String(localized: "婉婉没在这页找到活动，确认一下是不是版本公告？", bundle: .appLanguage)
        }
        return drafts
    }

    // MARK: - Backend JSON extraction

    private func backendExtract(
        searchText: String,
        gameName: String,
        articleURL: URL?,
        entitlementTier: EntitlementTier,
        appStoreTransactionJWS: String?
    ) async -> [AIEventDraft] {
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
                text: searchText,
                serverUtcOffsetMinutes: HoYoServer.current.utcOffsetHours * 60,
                language: AppLanguage.current.rawValue
              )) else {
            errorMessage = String(localized: "提取后端请求构建失败", bundle: .appLanguage)
            return []
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyBackendAuthHeaders(to: &req, appStoreTransactionJWS: appStoreTransactionJWS)
        req.httpBody        = bodyData
        req.timeoutInterval = 120

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let apiError = try? JSONDecoder().decode(ExtractionErrorResponse.self, from: data)
                if apiError?.error == "daily_limit_exceeded" {
                    quotaLimitMessage = apiError?.message ?? entitlementTier.extractionLimitMessage
                    return []
                }
                if apiError?.error == "rate_limited" {
                    errorMessage = apiError?.message ?? String(localized: "请求过于频繁，请稍后再试", bundle: .appLanguage)
                    return []
                }
                let message = apiError?.message ?? String(data: data, encoding: .utf8) ?? ""
                errorMessage = String(localized: "提取后端错误（\(http.statusCode)）：\(message.prefix(120))", bundle: .appLanguage)
                return []
            }

            guard let wrapper = try? JSONDecoder().decode(ExtractionResponse.self, from: data) else {
                errorMessage = String(localized: "提取结果格式异常，请重试", bundle: .appLanguage)
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
                    errorMessage = String(localized: "请求超时：处理长公告可能需要更久，请确认后端仍在运行后重试。", bundle: .appLanguage)
                case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
                    errorMessage = String(localized: "提取后端连接失败：请确认后端已启动，且手机和 Mac 在同一 Wi-Fi。", bundle: .appLanguage)
                case .notConnectedToInternet:
                    errorMessage = String(localized: "网络不可用：请检查当前网络连接。", bundle: .appLanguage)
                default:
                    errorMessage = String(localized: "网络请求失败：\(urlError.localizedDescription)", bundle: .appLanguage)
                }
            } else {
                errorMessage = String(localized: "提取失败：\(error.localizedDescription)", bundle: .appLanguage)
            }
            return []
        }
    }

    // MARK: - Codable models

    private func applyBackendAuthHeaders(to request: inout URLRequest, appStoreTransactionJWS: String?) {
        request.setValue(InstallID.current, forHTTPHeaderField: "X-Install-ID")

        guard let appStoreTransactionJWS,
              !appStoreTransactionJWS.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        request.setValue(appStoreTransactionJWS, forHTTPHeaderField: "X-App-Store-Transaction")
    }

    private struct ExtractionRequest: Encodable {
        let gameName: String
        let articleURL: String?
        let text: String
        // 公告写"服务器时间"或没写时区时，后端按这个时区换算。后端统一返回北京时间。
        let serverUtcOffsetMinutes: Int
        // 活动名按这个语言输出（zh-Hans / zh-Hant / en）。
        let language: String
    }

    private struct ExtractionResponse: Decodable {
        let events: [RawEvent]
    }

    private struct ExtractionErrorResponse: Decodable {
        let error: String?
        let message: String?
    }

    private struct QuotaResponse: Decodable {
        let canExtract: Bool
        let message: String?
    }

    private struct RawEvent: Decodable {
        let title:     String
        let startDate: String
        let endDate:   String
        let category:  String?
    }
}
