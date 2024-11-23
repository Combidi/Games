//
//  Created by Peter Combee on 21/11/2024.
//

import Foundation

struct CodableGamesStore: GameCacheRetrievable, GameCacheStorable {
        
    private struct CodableGame: Codable {
        let id: Int
        let name: String
        let imageId: String?
    }
    
    private let storeUrl: URL
    
    init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    func retrieveGames() throws -> [Game] {
        guard let data = try? Data(contentsOf: storeUrl) else { return [] }
        let codableGames = try JSONDecoder().decode([CodableGame].self, from: data)
        let games = codableGames.map {
            Game(id: $0.id, name: $0.name, imageId: $0.imageId)
        }
        return games
    }
    
    func store(games: [Game]) throws {
        let codableGames = games.map {
            CodableGame(id: $0.id, name: $0.name, imageId: $0.imageId)
        }
        let encoded = try JSONEncoder().encode(codableGames)
        try encoded.write(to: storeUrl)
    }
}
