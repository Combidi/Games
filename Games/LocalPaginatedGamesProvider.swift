//
//  Created by Peter Combee on 20/11/2024.
//

protocol GameCacheRetrievable {
    func retrieveGames() throws -> [Game]?
}

struct LocalPaginatedGamesProvider: PaginatedGamesProvider {
    
    struct MissingGamesError: Error {}
    
    typealias Offset = Int
    
    private let cache: GameCacheRetrievable
    private let loadMore: (Offset) async throws -> PaginatedGames
    
    init(cache: GameCacheRetrievable, loadMore: @escaping (Offset) async throws -> PaginatedGames) {
        self.cache = cache
        self.loadMore = loadMore
    }
    
    func getGames() throws -> PaginatedGames {
        let games = try cache.retrieveGames()
        guard let games else { throw MissingGamesError() }
        return PaginatedGames(games: games, loadMore: {
            try await loadMore(games.count)
        })
    }
}
