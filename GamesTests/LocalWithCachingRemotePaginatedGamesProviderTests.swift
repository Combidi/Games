//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games
 
final class LocalWithCachingRemotePaginatedGamesProviderTests: XCTestCase {
    
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
    
    func test_getGames_withNonEmptyGamesCache_deliversGamesFromRemote() async throws {
        
        let cache = Cache(stub: .success([makeGame(id: 1)]))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let remoteGames = [
            makeGame(id: 2),
            makeGame(id: 3)
        ]
        remoteGamesProvider.stub = .success(remoteGames)
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
            .makeCachingRemotePaginatedGamesProvider()
        
        let loadedGames = try await getGames().games
        
        XCTAssertEqual(loadedGames, remoteGames)
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
    
    func test_loadMore_deliversAccumulatedGamesFromRemote() async throws {
        
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: Cache(stub: .success([])),
            remoteGamesProvider: remoteGamesProvider
        )
            .makeCachingRemotePaginatedGamesProvider()
        
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
        
        let firstPage = try await getGames()
        
        XCTAssertEqual(firstPage.games.map(\.id), firstBatchOfRemoteGames.map(\.id))
        
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
        
        let secondPage = try await firstPage.loadMore!()
        
        XCTAssertEqual(secondPage.games.map(\.id), (firstBatchOfRemoteGames + secondBatchOfRemoteGames).map(\.id))
        
        let thirdBatchOfRemoteGames = [
            makeGame(id: 23),
            makeGame(id: 24)
        ]
        remoteGamesProvider.stub = .success(thirdBatchOfRemoteGames)
        
        let thirdPage = try await secondPage.loadMore!()
        
        XCTAssertEqual(thirdPage.games.map(\.id), (firstBatchOfRemoteGames + secondBatchOfRemoteGames + thirdBatchOfRemoteGames).map(\.id))
        
        XCTAssertNil(thirdPage.loadMore, "Expected no load more when the last page has been loaded")
    }

    func test_loadMore_storesAccumulatedGamesInCache() async throws {
        
        let cache = Cache(stub: .success([]))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeCachingRemotePaginatedGamesProvider()
                
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

        let firstPage = try await getGames()
                
        XCTAssertEqual(try cache.retrieveGames().map(\.id), firstBatchOfRemoteGames.map(\.id))

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
        
        let secondPage = try await firstPage.loadMore!()
        
        XCTAssertEqual(try cache.retrieveGames().map(\.id), (firstBatchOfRemoteGames + secondBatchOfRemoteGames).map(\.id))
                
        let thirdBatchOfRemoteGames = [
            makeGame(id: 23),
            makeGame(id: 24)
        ]
        remoteGamesProvider.stub = .success(thirdBatchOfRemoteGames)

        _ = try await secondPage.loadMore!()
        
        XCTAssertEqual(try cache.retrieveGames().map(\.id), (firstBatchOfRemoteGames + secondBatchOfRemoteGames + thirdBatchOfRemoteGames).map(\.id))
    }
}

// MARK: - Helpers

private func makeGame(id: Int) -> Game {
    Game(id: id, name: "Game \(id)", imageId: nil)
}

private final class Cache: GamesCache {
            
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
