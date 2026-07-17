import Foundation

enum APIConfig {
    private static let railwayBackendBaseURL = "https://yanwanwan-production-edd3.up.railway.app"
    private static let useLocalBackendInDebug = false

    #if DEBUG
    static let aiBackendBaseURL = useLocalBackendInDebug ? localBackendBaseURL : railwayBackendBaseURL
    #else
    static let aiBackendBaseURL = railwayBackendBaseURL
    #endif

    #if targetEnvironment(simulator)
    private static let localBackendBaseURL = "http://127.0.0.1:8787"
    #else
    private static let localBackendBaseURL = "http://192.168.110.98:8787"
    #endif

    static var aiExtractorURL: URL? {
        let trimmedBaseURL = aiBackendBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmedBaseURL)/api/extract-events")
    }

    static var quotaURL: URL? {
        let trimmedBaseURL = aiBackendBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmedBaseURL)/api/quota")
    }

    static var isAIBackendConfigured: Bool {
        !aiBackendBaseURL.isEmpty && !aiBackendBaseURL.contains("your-backend.example.com")
    }
}
