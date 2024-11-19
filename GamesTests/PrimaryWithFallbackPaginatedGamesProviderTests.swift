//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private struct PrimaryWithFallbackGamesProvider {
    
    private let primaryProvider: PaginatedGamesProviderStub
    private let fallbackProvider: PaginatedGamesProviderStub
    
    init(
        primaryProvider: PaginatedGamesProviderStub,
        fallbackProvider: PaginatedGamesProviderStub
    ) {
        self.primaryProvider = primaryProvider
        self.fallbackProvider = fallbackProvider
    }
    
    func getGames() throws -> [Game] {
        do { return try primaryProvider.getGames() }
        catch { return try fallbackProvider.getGames() }
    }
}

final class PrimaryWithFallbackGamesProviderTests: XCTestCase {
    
    func test_getGames_deliversGamesFromPrimaryProvider() throws {
        let primaryProvider = PaginatedGamesProviderStub()
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        primaryProvider.stub = .success(games)
        let sut = PrimaryWithFallbackGamesProvider(
            primaryProvider: primaryProvider,
            fallbackProvider: PaginatedGamesProviderStub()
        )

        let result = try sut.getGames()

        XCTAssertEqual(result, games)
    }
    
    func test_getGames_deliversGamesFromFallbackProviderOnPrimaryProviderError() throws {
        let primaryProvider = PaginatedGamesProviderStub()
        primaryProvider.stub = .failure(NSError(domain: "any", code: 0))
        let fallbackProvider = PaginatedGamesProviderStub()
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        fallbackProvider.stub = .success(games)
        let sut = PrimaryWithFallbackGamesProvider(
            primaryProvider: primaryProvider,
            fallbackProvider: fallbackProvider
        )

        let result = try sut.getGames()

        XCTAssertEqual(result, games)
    }

}

// MARK: - Helpers

private final class PaginatedGamesProviderStub {
    var stub: Result<[Game], Error> = .success([])
    
    func getGames() throws -> [Game] {
        try stub.get()
    }
}
