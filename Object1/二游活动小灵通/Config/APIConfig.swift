import Foundation

enum APIConfig {
    #if DEBUG
    #if targetEnvironment(simulator)
    // The iOS Simulator can reach the Mac host through 127.0.0.1.
    static let aiBackendBaseURL = "http://127.0.0.1:8787"
    #else
    // Real devices must use the Mac's Wi-Fi/LAN IP. Update this if your IP changes.
    static let aiBackendBaseURL = "http://192.168.110.98:8787"
    #endif
    #else
    static let aiBackendBaseURL = "https://yanwanwan-production-edd3.up.railway.app"
    #endif

    static var aiExtractorURL: URL? {
        let trimmedBaseURL = aiBackendBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmedBaseURL)/api/extract-events")
    }

    static var isAIBackendConfigured: Bool {
        !aiBackendBaseURL.isEmpty && !aiBackendBaseURL.contains("your-backend.example.com")
    }
}
