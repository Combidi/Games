//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private struct CachingGamesProviderDecorator {
    
    private let provider: PaginatedGamesProviderStub
    
    init(provider: PaginatedGamesProviderStub) {
        self.provider = provider
    }
    
    func getGames() throws -> PaginatedGames {
        try provider.getGames()
    }
}

final class CachingGamesProviderDecodatorTests: XCTestCase {
    
    func test_getGames_deliversGamesReceivedFromProvider() throws {
        let provider = PaginatedGamesProviderStub()
        let sut = CachingGamesProviderDecorator(provider: provider)
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
        let sut = CachingGamesProviderDecorator(provider: provider)
        let providerError = NSError(domain: "any", code: 3)
        provider.stub = .failure(providerError)
        
        do {
            let result = try sut.getGames()
            XCTFail("Expected getGames to throw, got \(result) instaead")
        } catch {
            XCTAssertEqual(error as NSError, providerError)
        }
    }
}

// MARK: - Helpers

private final class PaginatedGamesProviderStub: PaginatedGamesProvider {
    var stub: Result<PaginatedGames, Error> = .success(PaginatedGames(games: [], loadMore: nil))
    
    func getGames() throws -> PaginatedGames {
        try stub.get()
    }
}
