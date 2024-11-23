//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private typealias PaginatedGamesProvider = () async throws -> PaginatedGames

private struct PaginatedGamesProviderAssembler {
    
    private let cache: GameCacheRetrievable & GameCacheStorable
    private let remoteGamesProvider: RemoteGamesProvider
    private let pageSize = 10

    init(
        cache: GameCacheRetrievable & GameCacheStorable,
        remoteGamesProvider: RemoteGamesProvider
    ) {
        self.cache = cache
        self.remoteGamesProvider = remoteGamesProvider
    }
    
    func makeCachingRemotePaginatedGamesProvider() -> PaginatedGamesProvider {
        {
            guard let cachedGames = try? cache.retrieveGames(), !cachedGames.isEmpty else {
                return try await loadMore(currentGames: [])
            }
            return PaginatedGames(
                games: cachedGames,
                loadMore: { try await loadMore(currentGames: cachedGames) }
            )
        }
    }

    private func loadMore(currentGames: [Game]) async throws -> PaginatedGames {
        let nextBatchOfGames = try await remoteGamesProvider.getGames(
            limit: pageSize,
            offset: currentGames.count
        )
        let games = currentGames + nextBatchOfGames
        try cache.store(games: games)
        let reachedEnd = nextBatchOfGames.count != pageSize
        let page =  PaginatedGames(
            games: games,
            loadMore: reachedEnd ? nil : { try await loadMore(currentGames: games) }
        )
        return page
    }
}
 
final class RemoteWithLocalFallbackGamesProviderIntegrationTests: XCTestCase {
    
    func test_getGames_withEmptyGamesCache_deliversGamesFromRemote() async throws {
        
        let cache = Cache(stub: .success([]))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let gamesFromRemote = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        remoteGamesProvider.stub = .success(gamesFromRemote)
        
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeCachingRemotePaginatedGamesProvider()
        
        let loadedGames = try await getGames().games
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }
    
    func test_getGames_withGamesCacheError_deliversGamesFromRemote() async throws {
        
        let cache = Cache(stub: .failure(NSError(domain: "", code: 1)))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let gamesFromRemote = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        remoteGamesProvider.stub = .success(gamesFromRemote)
        
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeCachingRemotePaginatedGamesProvider()
        
        let loadedGames = try await getGames().games
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }
    
    func test_getGames_withNonEmptyGamesCache_deliversGamesFromCache() async throws {
        
        let cachedGames = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        let cache = Cache(stub: .success(cachedGames))
        
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: RemoteGamesProviderStub()
        )
        .makeCachingRemotePaginatedGamesProvider()

        let loadedGames = try await getGames().games
        
        XCTAssertEqual(loadedGames, cachedGames)
    }
    
    func test_getGames_cachesGamesReceivedFromRemote() async throws {
        
        let cache = Cache(stub: .success([]))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeCachingRemotePaginatedGamesProvider()
        let remoteGames = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        remoteGamesProvider.stub = .success(remoteGames)
        
        _ = try await getGames().games
        
        let cachedGames = try cache.retrieveGames()
        
        XCTAssertEqual(cachedGames, remoteGames)
    }
    
    func test_loadMore_withNonEmptyGameCache_deliversAccumulatedGamesFromCacheAndRemote() async throws {
        
        let cachedGames = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        let cache = Cache(stub: .success(cachedGames))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeCachingRemotePaginatedGamesProvider()

                
        let firstPage = try await getGames()
        
        XCTAssertEqual(firstPage.games.map(\.id), cachedGames.map(\.id))

        let firstBatchOfRemoteGames = [
            makeGame(id: 3),
            makeGame(id: 4),
            makeGame(id: 5),
            makeGame(id: 6),
            makeGame(id: 7),
            makeGame(id: 8),
            makeGame(id: 9),
            makeGame(id: 10),
            makeGame(id: 11),
            makeGame(id: 12)
        ]
        remoteGamesProvider.stub = .success(firstBatchOfRemoteGames)
        
        let secondPage = try await firstPage.loadMore!()
        
        XCTAssertEqual(secondPage.games.map(\.id), (cachedGames + firstBatchOfRemoteGames).map(\.id))
        
        let secondBatchOfRemoteGames = [
            makeGame(id: 13),
            makeGame(id: 14),
            makeGame(id: 15),
            makeGame(id: 16),
            makeGame(id: 17),
            makeGame(id: 18),
            makeGame(id: 19),
            makeGame(id: 20),
            makeGame(id: 21),
            makeGame(id: 22),
        ]
        remoteGamesProvider.stub = .success(secondBatchOfRemoteGames)
        
        let thirdPage = try await secondPage.loadMore!()
        
        XCTAssertEqual(thirdPage.games.map(\.id), (cachedGames + firstBatchOfRemoteGames + secondBatchOfRemoteGames).map(\.id))

        let thirdBatchOfRemoteGames = [
            makeGame(id: 23),
            makeGame(id: 24)
        ]
        remoteGamesProvider.stub = .success(thirdBatchOfRemoteGames)
        
        let fourthPage = try await thirdPage.loadMore!()
        
        XCTAssertEqual(fourthPage.games.map(\.id), (cachedGames + firstBatchOfRemoteGames + secondBatchOfRemoteGames + thirdBatchOfRemoteGames).map(\.id))
        
        XCTAssertNil(fourthPage.loadMore, "Expected no load more when the last page has been loaded")
    }
}

// MARK: - Helpers

private func makeGame(id: Int) -> Game {
    Game(id: id, name: "Game \(id)", imageId: nil)
}

private final class Cache: GameCacheRetrievable, GameCacheStorable {
            
    private var stub: Result<[Game], Error>
       
    init(stub: Result<[Game], Error>) {
        self.stub = stub
    }
    
    func retrieveGames() throws -> [Game] {
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
