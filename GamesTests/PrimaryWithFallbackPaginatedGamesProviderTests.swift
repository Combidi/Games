//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

final class PrimaryWithFallbackGamesProviderTests: XCTestCase {
    
    private let primaryProvider = PaginatedGamesProviderStub()
    private let fallbackProvider = PaginatedGamesProviderStub()
    private lazy var sut = PrimaryWithFallbackGamesProvider(
        primaryProvider: primaryProvider,
        fallbackProvider: fallbackProvider
    )

    func test_getGames_deliversGamesFromPrimaryProvider() async throws {
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        primaryProvider.stub = .success(PaginatedGames(games: games, loadMore: nil))

        let result = try await sut.getGames()

        XCTAssertEqual(result.games, games)
    }
    
    func test_getGames_deliversGamesFromFallbackProviderOnPrimaryProviderError() async throws {
        primaryProvider.stub = .failure(NSError(domain: "any", code: 0))
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        fallbackProvider.stub = .success(PaginatedGames(games: games, loadMore: nil))

        let result = try await sut.getGames()

        XCTAssertEqual(result.games, games)
    }

    func test_getGames_deliversErrorOnFallbackProviderError() async throws {
        primaryProvider.stub = .failure(NSError(domain: "any", code: 0))
        
        let fallbackProviderError = NSError(domain: "any", code: 1)
        fallbackProvider.stub = .failure(fallbackProviderError)

        do {
            let result = try await sut.getGames()
            XCTFail("Expected getGames to throw, got \(result) instead")
        } catch {
            XCTAssertEqual(error as NSError, fallbackProviderError)
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
