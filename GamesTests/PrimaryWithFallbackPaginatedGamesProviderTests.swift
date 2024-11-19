//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private struct PrimaryWithFallbackGamesProvider {
    
    private let primaryProvider: PaginatedGamesProviderStub
    
    init(primaryProvider: PaginatedGamesProviderStub) {
        self.primaryProvider = primaryProvider
    }
    
    func getGames() -> [Game] {
        primaryProvider.getGames()
    }
}

final class PrimaryWithFallbackGamesProviderTests: XCTestCase {
    
    func test_getGames_deliversGamesDeliveredByPrimaryProvider() {
        let primaryProvider = PaginatedGamesProviderStub()
        let games = [
            Game(id: 0, name: "first", imageId: nil),
            Game(id: 1, name: "second", imageId: nil)
        ]
        primaryProvider.stub = .success(games)
        let sut = PrimaryWithFallbackGamesProvider(
            primaryProvider: primaryProvider
        )

        let result = sut.getGames()

        XCTAssertEqual(result, games)
    }
}

// MARK: - Helpers

private final class PaginatedGamesProviderStub {
    var stub: Result<[Game], Error> = .success([])
    
    func getGames() -> [Game] {
        try! stub.get()
    }
}
