//
//  Created by Peter Combee on 20/11/2024.
//

protocol GameCacheRetrievable {
    func retrieveGames() -> [Game]?
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
        guard let games = cache.retrieveGames() else { throw MissingGamesError() }
        return PaginatedGames(games: games, loadMore: {
            try await loadMore(games.count)
        })
    }
}
