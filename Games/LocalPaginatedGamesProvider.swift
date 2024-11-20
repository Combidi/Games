//
//  Created by Peter Combee on 20/11/2024.
//

protocol GameCacheRetrievable {
    func cachedGames() -> [Game]?
}

struct LocalPaginatedGamesProvider: PaginatedGamesProvider {
    
    struct MissingGamesError: Error {}
    
    typealias Offset = Int
    
    private let cache: GameCacheRetrievable
    private let loadMore: (Offset) -> PaginatedGames
    
    init(cache: GameCacheRetrievable, loadMore: @escaping (Offset) -> PaginatedGames) {
        self.cache = cache
        self.loadMore = loadMore
    }
    
    func getGames() throws -> PaginatedGames {
        guard let games = cache.cachedGames() else { throw MissingGamesError() }
        return PaginatedGames(games: games, loadMore: {
            loadMore(games.count)
        })
    }
}
