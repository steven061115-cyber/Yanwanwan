import Foundation

enum APIConfig {
    private static let railwayBackendBaseURL = "https://yanwanwan-production-edd3.up.railway.app"
    static let aiBackendBaseURL = railwayBackendBaseURL

    private static var trimmedAIBackendBaseURL: String {
        aiBackendBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    static var aiExtractorURL: URL? {
        URL(string: "\(trimmedAIBackendBaseURL)/api/extract-events")
    }

    static var quotaURL: URL? {
        URL(string: "\(trimmedAIBackendBaseURL)/api/quota")
    }

    static func calendarURL(game: String, lang: String) -> URL? {
        URL(string: "\(trimmedAIBackendBaseURL)/api/calendar/\(game)?lang=\(lang)")
    }

    // The web pages come in every app language; pass the in-app choice so they match the UI.
    static var privacyPolicyURL: URL? {
        URL(string: "\(trimmedAIBackendBaseURL)/privacy?lang=\(AppLanguage.current.rawValue)")
    }

    static var termsOfServiceURL: URL? {
        URL(string: "\(trimmedAIBackendBaseURL)/terms?lang=\(AppLanguage.current.rawValue)")
    }

    static var dataDeletionURL: URL? {
        URL(string: "\(trimmedAIBackendBaseURL)/api/user-data")
    }

    static var isAIBackendConfigured: Bool {
        !aiBackendBaseURL.isEmpty && !aiBackendBaseURL.contains("your-backend.example.com")
    }
}
