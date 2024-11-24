//
//  Created by Peter Combee on 23/11/2024.
//

import XCTest
@testable import Games
 
final class CachingRemotePaginatedGamesProviderTests: XCTestCase {

    func test_getGames_withEmptyGamesCache_deliversGamesFromRemote() async throws {
        
        let cache = GamesCacheStub(stub: .success([]))
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
        .makeLocalWithCachingRemotePaginatedGamesProvider()
        
        let loadedGames = try await getGames().items
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }
    
    func test_getGames_withGamesCacheError_deliversGamesFromRemote() async throws {
        
        let cache = GamesCacheStub(stub: .failure(NSError(domain: "", code: 1)))
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
        .makeLocalWithCachingRemotePaginatedGamesProvider()
        
        let loadedGames = try await getGames().items
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }
    
    func test_getGames_withNonEmptyGamesCache_deliversGamesFromCache() async throws {
        
        let cachedGames = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        let cache = GamesCacheStub(stub: .success(cachedGames))
        
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: RemoteGamesProviderStub()
        )
        .makeLocalWithCachingRemotePaginatedGamesProvider()

        let loadedGames = try await getGames().items
        
        XCTAssertEqual(loadedGames, cachedGames)
    }
    
    func test_getGames_cachesGamesReceivedFromRemote() async throws {
        
        let cache = GamesCacheStub(stub: .success([]))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeLocalWithCachingRemotePaginatedGamesProvider()
        let remoteGames = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        remoteGamesProvider.stub = .success(remoteGames)
        
        _ = try await getGames().items
        
        let cachedGames = try cache.retrieveGames()
        
        XCTAssertEqual(cachedGames, remoteGames)
    }
    
    func test_loadMore_withNonEmptyGameCache_deliversAccumulatedGamesFromCacheAndRemote() async throws {
        
        let cachedGames = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]
        let cache = GamesCacheStub(stub: .success(cachedGames))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeLocalWithCachingRemotePaginatedGamesProvider()
                
        let firstPage = try await getGames()
        
        XCTAssertEqual(firstPage.items.map(\.id), cachedGames.map(\.id))

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
        
        XCTAssertEqual(secondPage.items.map(\.id), (cachedGames + firstBatchOfRemoteGames).map(\.id))
        
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
        
        XCTAssertEqual(thirdPage.items.map(\.id), (cachedGames + firstBatchOfRemoteGames + secondBatchOfRemoteGames).map(\.id))

        let thirdBatchOfRemoteGames = [
            makeGame(id: 23),
            makeGame(id: 24)
        ]
        remoteGamesProvider.stub = .success(thirdBatchOfRemoteGames)
        
        let fourthPage = try await thirdPage.loadMore!()
        
        XCTAssertEqual(fourthPage.items.map(\.id), (cachedGames + firstBatchOfRemoteGames + secondBatchOfRemoteGames + thirdBatchOfRemoteGames).map(\.id))
        
        XCTAssertNil(fourthPage.loadMore, "Expected no load more when the last page has been loaded")
    }
    
    func test_loadMore_storesAccumulatedGamesInCache() async throws {
        
        let cache = GamesCacheStub(stub: .success([]))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
        .makeLocalWithCachingRemotePaginatedGamesProvider()
                
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
