//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private struct CachingGamesProviderDecorator: PaginatedGamesProvider {
    
    private let provider: PaginatedGamesProviderStub
    private let cache: Cache
    
    init(provider: PaginatedGamesProviderStub, cache: Cache) {
        self.provider = provider
        self.cache = cache
    }
    
    func getGames() throws -> PaginatedGames {
        let page = try provider.getGames()
        cache.cachedGames = page.games
        return page
    }
}

final class CachingGamesProviderDecodatorTests: XCTestCase {
    
    func test_getGames_deliversGamesReceivedFromProvider() throws {
        let provider = PaginatedGamesProviderStub()
        let sut = CachingGamesProviderDecorator(
            provider: provider,
            cache: Cache()
        )
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        provider.stub = .success(PaginatedGames(games: games, loadMore: nil))
        
        let result = try sut.getGames()
        
        XCTAssertEqual(result.games, games)
    }
    
    func test_getGames_deliversErrorOnProviderError() {
        let provider = PaginatedGamesProviderStub()
        let sut = CachingGamesProviderDecorator(
            provider: provider,
            cache: Cache()
        )
        let providerError = NSError(domain: "any", code: 3)
        provider.stub = .failure(providerError)
        
        do {
            let result = try sut.getGames()
            XCTFail("Expected getGames to throw, got \(result) instaead")
        } catch {
            XCTAssertEqual(error as NSError, providerError)
        }
    }
    
    func test_getGames_storesReceivedGamesInCache() throws {
        let provider = PaginatedGamesProviderStub()
        let cache = Cache()
        let sut = CachingGamesProviderDecorator(provider: provider, cache: cache)
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        provider.stub = .success(PaginatedGames(games: games, loadMore: nil))
        
        _ = try sut.getGames()
        
        XCTAssertEqual(cache.cachedGames, games)
    }
}

// MARK: - Helpers

private final class PaginatedGamesProviderStub: PaginatedGamesProvider {
    var stub: Result<PaginatedGames, Error> = .success(PaginatedGames(games: [], loadMore: nil))
    
    func getGames() throws -> PaginatedGames {
        try stub.get()
    }
}

private final class Cache {
    var cachedGames: [Game] = []
}
