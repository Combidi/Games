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
        let cache = Cache(stub: .success(games))
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { _ in PaginatedGames(games: [], loadMore: nil) }
        )

        let result = try sut.getGames()
        
        XCTAssertEqual(result.games, games)
    }
    
    func test_getGames_withoutCachedGames_deliversError() {
        let cache = Cache(stub: .success(nil))
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { _ in PaginatedGames(games: [], loadMore: nil) }
        )

        XCTAssertThrowsError(try sut.getGames()) { error in
            XCTAssertTrue(error is LocalPaginatedGamesProvider.MissingGamesError)
        }
    }

    func test_getGames_withoutEmptyCachedGames_deliversError() {
        let cache = Cache(stub: .success([]))
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { _ in PaginatedGames(games: [], loadMore: nil) }
        )

        XCTAssertThrowsError(try sut.getGames()) { error in
            XCTAssertTrue(error is LocalPaginatedGamesProvider.MissingGamesError)
        }
    }
    
    func test_getGames_deliversErrorOnCacheRetievalError() {
        let cacheRetrievalError = NSError(domain: "any", code: 10)
        let cache = Cache(stub: .failure(cacheRetrievalError))
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { _ in PaginatedGames(games: [], loadMore: nil) }
        )

        XCTAssertThrowsError(try sut.getGames()) { error in
            XCTAssertEqual(error as NSError, cacheRetrievalError)
        }
    }
    
    func test_loadMore_loadMoreProvidingOffsetFromWhichToLoadMore() async throws {
        let amountOfCachedGames = 12
        let cachedGames = Array(
            repeating: Game(id: 0, name: "any", imageId: nil),
            count: amountOfCachedGames
        )
        let cache = Cache(stub: .success(cachedGames))
        var capturedOffset: Int?
        let additionalGames = [
            Game(id: 1, name: "additionalGame", imageId: nil)
        ]
        let sut = LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { offset in
                capturedOffset = offset
                return PaginatedGames(games: additionalGames, loadMore: nil)
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
        
    private let stub: Result<[Game]?, Error>
    
    init(stub: Result<[Game]?, Error>) {
        self.stub = stub
    }
    
    func retrieveGames() throws -> [Game]? {
        try stub.get()
    }
}
