//
//  Created by Peter Combee on 23/11/2024.
//

struct PaginatedGamesProviderAssembler {
    
    private let cache: GameCacheRetrievable & GameCacheStorable
    private let remoteGamesProvider: RemoteGamesProvider
    private let pageSize = 10

    init(
        cache: GameCacheRetrievable & GameCacheStorable,
        remoteGamesProvider: RemoteGamesProvider
    ) {
        self.cache = cache
        self.remoteGamesProvider = remoteGamesProvider
    }
    
    func makeCachingRemotePaginatedGamesProvider() -> PaginatedGamesProvider {
        {
            guard let cachedGames = try? cache.retrieveGames(), !cachedGames.isEmpty else {
                return try await loadMore(currentGames: [])
            }
            return PaginatedGames(
                games: cachedGames,
                loadMore: { try await loadMore(currentGames: cachedGames) }
            )
        }
    }

    private func loadMore(currentGames: [Game]) async throws -> PaginatedGames {
        let nextBatchOfGames = try await remoteGamesProvider.getGames(
            limit: pageSize,
            offset: currentGames.count
        )
        let games = currentGames + nextBatchOfGames
        try cache.store(games: games)
        let reachedEnd = nextBatchOfGames.count != pageSize
        let page =  PaginatedGames(
            games: games,
            loadMore: reachedEnd ? nil : { try await loadMore(currentGames: games) }
        )
        return page
    }
}
