//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

protocol GameCacheRetrievable {
    func cachedGames() -> [Game]
}

private struct LocalPaginatedGamesProvider {
    
    private let cache: GameCacheRetrievable
    
    init(cache: GameCacheRetrievable) {
        self.cache = cache
    }
    
    func getGames() -> PaginatedGames {
        PaginatedGames(games: cache.cachedGames(), loadMore: nil)
    }
}

final class LocalPaginatedGamesProviderTests: XCTestCase {
    
    func test_getGames_withCachedGames_deliversGamesFromCache() {
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        let cache = Cache(games: games)
        let sut = LocalPaginatedGamesProvider(cache: cache)
        
        let result = sut.getGames()
        
        XCTAssertEqual(result.games, games)
    }
}

// MARK: - Helpers

private final class Cache: GameCacheRetrievable {
    
    private let games: [Game]
    
    init(games: [Game]) {
        self.games = games
    }
    
    func cachedGames() -> [Game] {
        games
    }
}
