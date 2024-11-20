//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

protocol GameCacheRetrievable {
    func cachedGames() -> [Game]?
}

private struct LocalPaginatedGamesProvider {
    
    struct MissingGamesError: Error {}
    
    private let cache: GameCacheRetrievable
    
    init(cache: GameCacheRetrievable) {
        self.cache = cache
    }
    
    func getGames() throws -> PaginatedGames {
        guard let games = cache.cachedGames() else { throw MissingGamesError() }
        return PaginatedGames(games: games, loadMore: nil)
    }
}

final class LocalPaginatedGamesProviderTests: XCTestCase {
    
    func test_getGames_withCachedGames_deliversGamesFromCache() throws {
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        let cache = Cache(games: games)
        let sut = LocalPaginatedGamesProvider(cache: cache)
        
        let result = try sut.getGames()
        
        XCTAssertEqual(result.games, games)
    }

    func test_getGames_withoutCachedGames_deliversError() {
        let cache = Cache(games: nil)
        let sut = LocalPaginatedGamesProvider(cache: cache)
                
        do {
            let result = try sut.getGames()
            XCTFail("Expected getGames to throw error, got \(result) instead")
        } catch {
            XCTAssertTrue(error is LocalPaginatedGamesProvider.MissingGamesError)
        }
    }
}

// MARK: - Helpers

private final class Cache: GameCacheRetrievable {
        
    private let games: [Game]?
    
    init(games: [Game]?) {
        self.games = games
    }
    
    func cachedGames() -> [Game]? {
        games
    }
}
