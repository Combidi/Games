//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

final class LocalPaginatedGamesProviderTests: XCTestCase {
    
    func test_getGames_withCachedGames_deliversGamesFromCache() throws {
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        let cache = Cache(games: games)
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { _ in PaginatedGames(games: [], loadMore: nil) }
        )

        let result = try sut.getGames()
        
        XCTAssertEqual(result.games, games)
    }
    
    func test_getGames_withoutCachedGames_deliversError() {
        let cache = Cache(games: nil)
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { _ in PaginatedGames(games: [], loadMore: nil) }
        )

        do {
            let result = try sut.getGames()
            XCTFail("Expected getGames to throw error, got \(result) instead")
        } catch {
            XCTAssertTrue(error is LocalPaginatedGamesProvider.MissingGamesError)
        }
    }

    func test_loadMore_loadMoreProvidingOffsetFromWhichToLoadMore() async throws {
        let amountOfCachedGames = 12
        let cachedGames = Array(
            repeating: Game(id: 0, name: "any", imageId: nil),
            count: amountOfCachedGames
        )
        let cache = Cache(games: cachedGames)
        var capturedOffset: Int?
        let additionalGames = [
            Game(id: 1, name: "additionalGame", imageId: nil)
        ]
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { offset in
                capturedOffset = offset
                return PaginatedGames(games: cachedGames + additionalGames, loadMore: nil)
            }
        )
        let firstPage = try sut.getGames()
        
        let secondPage = try await firstPage.loadMore?()
        
        XCTAssertEqual(capturedOffset, amountOfCachedGames)
        XCTAssertEqual(secondPage?.games, cachedGames + additionalGames)
    }
}

// MARK: - Helpers

private struct Cache: GameCacheRetrievable {
        
    private let games: [Game]?
    
    init(games: [Game]?) {
        self.games = games
    }
    
    func retrieveGames() -> [Game]? {
        games
    }
}
