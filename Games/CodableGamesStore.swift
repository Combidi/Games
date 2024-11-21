//
//  Created by Peter Combee on 21/11/2024.
//

import Foundation

struct CodableGamesStore: GameCacheRetrievable, GameCacheStorable {
        
    private let storeUrl: URL
    
    init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    func retrieveGames() throws -> [Game]? {
        guard let data = try? Data(contentsOf: storeUrl) else { return nil }
        return try JSONDecoder().decode([Game].self, from: data)
    }
    
    func store(games: [Game]) throws {
        let encoded = try JSONEncoder().encode(games)
        try encoded.write(to: storeUrl)
    }
}
