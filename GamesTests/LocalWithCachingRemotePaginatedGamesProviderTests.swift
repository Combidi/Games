//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games
 
final class LocalWithCachingRemotePaginatedGamesProviderTests: XCTestCase {
    
    private lazy var cache = GamesCacheStub()
    private lazy var remoteGamesProvider = RemoteGamesProviderStub()

    private func getGames() async throws -> Paginated<Game> {
        let sut = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        let getGames = sut.makeCachingRemotePaginatedGamesProvider()
        return try await getGames()
    }

    func test_getGames_withEmptyGamesCache_deliversGamesFromRemote() async throws {
        cache.stub = .success([])
        let gamesFromRemote = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        remoteGamesProvider.stub = .success(gamesFromRemote)
                
        let loadedGames = try await getGames().items
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }
    
    func test_getGames_withGamesCacheError_deliversGamesFromRemote() async throws {
        cache.stub = .failure(NSError(domain: "", code: 1))
        let gamesFromRemote = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        remoteGamesProvider.stub = .success(gamesFromRemote)
                
        let loadedGames = try await getGames().items
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }
    
    func test_getGames_withNonEmptyGamesCache_deliversGamesFromRemote() async throws {
        cache.stub = .success([makeGame(id: 1)])
        let remoteGames = [
            makeGame(id: 2),
            makeGame(id: 3)
        ]
        remoteGamesProvider.stub = .success(remoteGames)
        
        let loadedGames = try await getGames().items
        
        XCTAssertEqual(loadedGames, remoteGames)
    }
    
    func test_getGames_cachesGamesReceivedFromRemote() async throws {
        cache.stub = .success([])
        let remoteGames = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        remoteGamesProvider.stub = .success(remoteGames)
        
        _ = try await getGames().items
        
        let cachedGames = try cache.retrieveGames()
        
        XCTAssertEqual(cachedGames, remoteGames)
    }
    
    func test_loadMore_deliversAccumulatedGamesFromRemote() async throws {
        cache.stub = .success([])
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
        
        XCTAssertEqual(firstPage.items.map(\.id), firstBatchOfRemoteGames.map(\.id))
        
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
        
        XCTAssertEqual(secondPage.items.map(\.id), (firstBatchOfRemoteGames + secondBatchOfRemoteGames).map(\.id))
        
        let thirdBatchOfRemoteGames = [
            makeGame(id: 23),
            makeGame(id: 24)
        ]
        remoteGamesProvider.stub = .success(thirdBatchOfRemoteGames)
        
        let thirdPage = try await secondPage.loadMore!()
        
        XCTAssertEqual(thirdPage.items.map(\.id), (firstBatchOfRemoteGames + secondBatchOfRemoteGames + thirdBatchOfRemoteGames).map(\.id))
        
        XCTAssertNil(thirdPage.loadMore, "Expected no load more when the last page has been loaded")
    }

    func test_loadMore_storesAccumulatedGamesInCache() async throws {
        cache.stub = .success([])                
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
