//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private func makeLocalWithRemoteFallbackGamesProvider(
    cache: GameCacheRetrievable & GameCacheStorable,
    remoteGamesProvider: RemoteGamesProviderStub
) -> PaginatedGamesProvider {
    PrimaryWithFallbackPaginatedGamesProvider(
        primaryProvider: LocalPaginatedGamesProvider(
            cache: cache,
            loadMore: { offset in
                let remoteLoader = RemotePaginatedGamesProvider(
                    startOffset: offset,
                    remoteGamesProvider: remoteGamesProvider
                )
                return try await remoteLoader.getGames()
            }
        ),
        fallbackProvider: CachingPaginatedGamesProviderDecorator(
            provider: RemotePaginatedGamesProvider(
                remoteGamesProvider: remoteGamesProvider
            ),
            storage: cache
        )
    )
}

final class RemoteWithLocalFallbackGamesProviderIntegrationTests: XCTestCase {
    
    func test_getGames_withEmptyGamesCache_deliversGamesFromRemote() async throws {
        
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
    
    func test_getGames_withGamesCacheError_deliversGamesFromRemote() async throws {
        
        let cache = Cache(stub: .failure(NSError(domain: "", code: 1)))
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
    
    func test_getGames_withNonEmptyGamesCache_deliversGamesFromCache() async throws {
        
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
    
    func test_getGames_cachesGamesReceivedFromRemote() async throws {
        
        let cache = Cache(stub: .success(nil))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let sut = makeLocalWithRemoteFallbackGamesProvider(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        let remoteGames = [
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        remoteGamesProvider.stub = .success(remoteGames)
        
        _ = try await sut.getGames().games
        
        let cachedGames = try cache.retrieveGames()
        
        XCTAssertEqual(cachedGames, remoteGames)
    }
    
    func test_loadMore_withNonEmptyGameCache_deliversAccumulatedGamesFromCacheAndRemote() async throws {
        
        let cachedGames = [
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        let cache = Cache(stub: .success(cachedGames))
        let remoteGames = [
            Game(id: 3, name: "Game 3", imageId: nil),
            Game(id: 4, name: "Game 4", imageId: nil),
            Game(id: 5, name: "Game 5", imageId: nil),
            Game(id: 6, name: "Game 6", imageId: nil),
            Game(id: 7, name: "Game 7", imageId: nil),
            Game(id: 8, name: "Game 8", imageId: nil),
            Game(id: 9, name: "Game 9", imageId: nil),
            Game(id: 10, name: "Game 10", imageId: nil),
            Game(id: 11, name: "Game 11", imageId: nil),
            Game(id: 12, name: "Game 12", imageId: nil)
        ]
        let remoteGamesProvider = RemoteGamesProviderStub()
        remoteGamesProvider.stub = .success(remoteGames)
        
        let sut = makeLocalWithRemoteFallbackGamesProvider(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        
        let firstPage = try await sut.getGames()
        
        let loadMore = try XCTUnwrap(firstPage.loadMore)
        let secondPage = try await loadMore()
        
        XCTAssertEqual(secondPage.games.map(\.id), (cachedGames + remoteGames).map(\.id))
    }
}

// MARK: - Helpers

private final class Cache: GameCacheRetrievable, GameCacheStorable {
            
    private var stub: Result<[Game]?, Error>
       
    init(stub: Result<[Game]?, Error>) {
        self.stub = stub
    }
    
    func retrieveGames() throws -> [Game]? {
        try stub.get()
    }
    
    func store(games: [Game]) throws {
        self.stub = .success(games)
    }
}

private final class RemoteGamesProviderStub: RemoteGamesProvider {
            
    var stub: Result<[Game], Error> = .success([])
    
    func getGames(limit: Int, offset: Int) async throws -> [Game] {
        return try stub.get()
    }
}
