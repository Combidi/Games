//
//  Created by Peter Combee on 19/11/2024.
//

protocol GameCacheStorable {
    func store(games: [Game])
}

struct CachingGamesProviderDecorator: PaginatedGamesProvider {
    
    private let provider: PaginatedGamesProvider
    private let storage: GameCacheStorable
    
    init(provider: PaginatedGamesProvider, storage: GameCacheStorable) {
        self.provider = provider
        self.storage = storage
    }
    
    func getGames() async throws -> PaginatedGames {
        let page = try await provider.getGames()
        storage.store(games: page.games)
        return page
    }
}