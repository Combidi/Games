//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

protocol GameCacheStorable {
    func store(games: [Game])
}

private struct CachingGamesProviderDecorator: PaginatedGamesProvider {
    
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

final class CachingGamesProviderDecodatorTests: XCTestCase {
    
    func test_getGames_deliversGamesReceivedFromProvider() async throws {
        let provider = PaginatedGamesProviderStub()
        let sut = CachingGamesProviderDecorator(
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
        let sut = CachingGamesProviderDecorator(
            provider: provider,
            storage: InMemoryGameStorage()
        )
        let providerError = NSError(domain: "any", code: 3)
        provider.stub = .failure(providerError)
        
        do {
            let result = try await sut.getGames()
            XCTFail("Expected getGames to throw, got \(result) instaead")
        } catch {
            XCTAssertEqual(error as NSError, providerError)
        }
    }
    
    func test_getGames_storesReceivedGamesInCache() async throws {
        let provider = PaginatedGamesProviderStub()
        let storage = InMemoryGameStorage()
        let sut = CachingGamesProviderDecorator(provider: provider, storage: storage)
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        provider.stub = .success(PaginatedGames(games: games, loadMore: nil))
        
        _ = try await sut.getGames()
        
        XCTAssertEqual(storage.storedGames, games)
    }
}

// MARK: - Helpers

private final class PaginatedGamesProviderStub: PaginatedGamesProvider {
    var stub: Result<PaginatedGames, Error> = .success(PaginatedGames(games: [], loadMore: nil))
    
    func getGames() throws -> PaginatedGames {
        try stub.get()
    }
}

private final class InMemoryGameStorage: GameCacheStorable {
    
    private(set) var storedGames: [Game] = []
    
    func store(games: [Game]) {
        storedGames = games
    }
}
