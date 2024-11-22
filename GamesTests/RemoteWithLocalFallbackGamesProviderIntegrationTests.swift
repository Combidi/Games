//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private func makeLocalWithRemoteFallbackGamesProvider(
    cache: GameCacheRetrievable,
    remoteGamesProvider: RemoteGamesProviderStub
) -> PaginatedGamesProvider {
    PrimaryWithFallbackPaginatedGamesProvider(
        primaryProvider: LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { _ in  PaginatedGames(games: [], loadMore: nil) }
        ),
        fallbackProvider: RemotePaginatedGamesProvider(
            remoteGamesProvider: remoteGamesProvider
        )
    )
}

final class RemoteWithLocalFallbackGamesProviderIntegrationTests: XCTestCase {
    
    func test_getGames_withEmptyGamesCache_reliversGamesFromRemote() async throws {
        
        let cache = Cache(stub: .success([]))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let gamesFromRemote = [
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        remoteGamesProvider.stub = .success(gamesFromRemote)
        
        let sut = makeLocalWithRemoteFallbackGamesProvider(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        
        let loadedGames = try await sut.getGames().games
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }

    func test_getGames_withNonEmptyGamesCache_reliversGamesFromCache() async throws {
        
        let cachedGames = [
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        let cache = Cache(stub: .success(cachedGames))
        
        let sut = makeLocalWithRemoteFallbackGamesProvider(
            cache: cache,
            remoteGamesProvider: RemoteGamesProviderStub()
        )
        
        let loadedGames = try await sut.getGames().games
        
        XCTAssertEqual(loadedGames, cachedGames)
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

private final class RemoteGamesProviderStub: RemoteGamesProvider {
            
    var stub: Result<[Game], Error> = .success([])
    
    func getGames(limit: Int, offset: Int) async throws -> [Game] {
        return try stub.get()
    }
}
