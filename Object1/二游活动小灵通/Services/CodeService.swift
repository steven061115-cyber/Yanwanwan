import Foundation
import Observation

@MainActor
@Observable
final class CodeService {
    var codesByGame: [HoYoGame: [ExchangeCode]] = [:]
    var isLoading = false
    private var notifiedCodeIds: Set<String> = []

    private let baseURL = "https://api.ennead.cc"

    func refresh(games: [HoYoGame], seenIds: Set<String>,
                 onNew: @escaping ([ExchangeCode]) -> Void) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        for game in games {
            codesByGame[game] = await fetchCodes(for: game)
        }

        let allNew = codesByGame.values
            .flatMap { $0 }
            .filter { !seenIds.contains($0.id) && !notifiedCodeIds.contains($0.id) && $0.isActive }
        if !allNew.isEmpty {
            allNew.forEach { notifiedCodeIds.insert($0.id) }
            onNew(allNew)
        }
    }

    func codes(for game: HoYoGame) -> [ExchangeCode] {
        codesByGame[game] ?? []
    }

    // MARK: - Private

    private func fetchCodes(for game: HoYoGame) async -> [ExchangeCode] {
        guard let url = URL(string: "\(baseURL)/mihoyo/\(game.rawValue)/codes") else { return [] }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200
        else { return [] }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if let r = try? decoder.decode(CodeResponse.self, from: data) {
            let active   = r.active.map   { ExchangeCode.from($0, game: game, isActive: true)  }
            let inactive = r.inactive.map { ExchangeCode.from($0, game: game, isActive: false) }
            return active + inactive
        }
        return []
    }
}
