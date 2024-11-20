//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private struct LocalPaginatedGamesProvider {
    
    private let cache: Cache
    
    init(cache: Cache) {
        self.cache = cache
    }
    
    func getGames() -> PaginatedGames {
        PaginatedGames(games: cache.games, loadMore: nil)
    }
}

final class LocalPaginatedGamesProviderTests: XCTestCase {
    
    func test_getGames_deliversGamesFromCache() {
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

private final class Cache {
    
    let games: [Game]
    
    init(games: [Game]) {
        self.games = games
    }
}
