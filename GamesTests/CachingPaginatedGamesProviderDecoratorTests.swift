//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

final class CachingPaginatedGamesProviderDecoratorTests: XCTestCase {
    
    func test_getGames_deliversGamesReceivedFromProvider() async throws {
        let provider = PaginatedGamesProviderStub()
        let sut = CachingPaginatedGamesProviderDecorator(
            provider: provider,
            storage: InMemoryGameStorage()
        )
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        provider.stub = .success(PaginatedGames(games: games, loadMore: nil))
        
        let result = try await sut.getGames()
        
        XCTAssertEqual(result.games, games)
    }
    
    func test_getGames_deliversErrorOnProviderError() async {
        let provider = PaginatedGamesProviderStub()
        let sut = CachingPaginatedGamesProviderDecorator(
            provider: provider,
            storage: InMemoryGameStorage()
        )
        let providerError = NSError(domain: "any", code: 3)
        provider.stub = .failure(providerError)
        
        await assertThrowsAsyncError(try await sut.getGames()) { error in
            XCTAssertEqual(error as NSError, providerError)
        }        
    }
    
    func test_getGames_storesReceivedGamesInCache() async throws {
        let provider = PaginatedGamesProviderStub()
        let storage = InMemoryGameStorage()
        let sut = CachingPaginatedGamesProviderDecorator(provider: provider, storage: storage)
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        provider.stub = .success(PaginatedGames(games: games, loadMore: nil))
        
        _ = try await sut.getGames()
        
        XCTAssertEqual(storage.storedGames, games)
    }
    
    func test_getGames_deliversErrorOnCacheInsertionError() async {
        let provider = PaginatedGamesProviderStub()
        let storage = InMemoryGameStorage()
        let sut = CachingPaginatedGamesProviderDecorator(provider: provider, storage: storage)

        let storageInsertionError = NSError(domain: "any", code: 3)
        storage.throwOnInsertion = storageInsertionError
        
        await assertThrowsAsyncError(try await sut.getGames()) { error in
            XCTAssertEqual(error as NSError, storageInsertionError)
        }
    }
}

// MARK: - Helpers

private final class InMemoryGameStorage: GameCacheStorable {
    
    private(set) var storedGames: [Game] = []
    
    var throwOnInsertion: Error?
    
    func store(games: [Game]) throws {
        try throwOnInsertion.map { throw $0 }
        return storedGames = games
    }
}
