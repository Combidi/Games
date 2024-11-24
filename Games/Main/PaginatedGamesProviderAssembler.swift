//
//  Created by Peter Combee on 23/11/2024.
//

struct PaginatedGamesProviderAssembler {
    
    private let cache: GamesCache
    private let remoteGamesProvider: RemoteGamesProvider
    private let pageSize = 10

    init(
        cache: GamesCache,
        remoteGamesProvider: RemoteGamesProvider
    ) {
        self.cache = cache
        self.remoteGamesProvider = remoteGamesProvider
    }
    
    func makeLocalWithCachingRemotePaginatedGamesProvider() -> PaginatedGamesProvider {
        {
            guard let cachedGames = try? cache.retrieveGames(), !cachedGames.isEmpty else {
                return try await loadMore(currentGames: [])
            }
            return Paginated(
                items: cachedGames,
                loadMore: { try await loadMore(currentGames: cachedGames) }
            )
        }
    }
    
    func makeCachingRemotePaginatedGamesProvider() -> PaginatedGamesProvider {
        { try await loadMore(currentGames: []) }
    }

    private func loadMore(currentGames: [Game]) async throws -> Paginated<Game> {
        let nextBatchOfGames = try await remoteGamesProvider.getGames(
            limit: pageSize,
            offset: currentGames.count
        )
        let games = currentGames + nextBatchOfGames
        try cache.store(games: games)
        let reachedEnd = nextBatchOfGames.count != pageSize
        let page =  Paginated(
            items: games,
            loadMore: reachedEnd ? nil : { try await loadMore(currentGames: games) }
        )
        return page
    }
}
