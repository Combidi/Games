//
//  Created by Peter Combee on 19/11/2024.
//

import XCTest
@testable import Games

private typealias PaginatedGamesProvider = () async throws -> PaginatedGames

private struct PaginatedGamesProviderAssembler {
    
    private let cache: GameCacheRetrievable & GameCacheStorable
    private let remoteGamesProvider: RemoteGamesProviderStub
    private let pageSize = 10

    init(cache: GameCacheRetrievable & GameCacheStorable, remoteGamesProvider: RemoteGamesProviderStub) {
        self.cache = cache
        self.remoteGamesProvider = remoteGamesProvider
    }
    
    func makeLocalWithRemoteFallbackGamesProvider() -> PaginatedGamesProvider {
        {
            let cachedGames = (try? cache.retrieveGames() ?? []) ?? []
            if cachedGames.isEmpty {
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
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        remoteGamesProvider.stub = .success(gamesFromRemote)
        
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
            .makeLocalWithRemoteFallbackGamesProvider()
        
        let loadedGames = try await getGames().games
        
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
        
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
            .makeLocalWithRemoteFallbackGamesProvider()
        
        let loadedGames = try await getGames().games
        
        XCTAssertEqual(loadedGames, gamesFromRemote)
    }
    
    func test_getGames_withNonEmptyGamesCache_deliversGamesFromCache() async throws {
        
        let cachedGames = [
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        let cache = Cache(stub: .success(cachedGames))
        
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: RemoteGamesProviderStub()
        )
            .makeLocalWithRemoteFallbackGamesProvider()
        
        let loadedGames = try await getGames().games
        
        XCTAssertEqual(loadedGames, cachedGames)
    }
    
    func test_getGames_cachesGamesReceivedFromRemote() async throws {
        
        let cache = Cache(stub: .success(nil))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        )
            .makeLocalWithRemoteFallbackGamesProvider()
        let remoteGames = [
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        remoteGamesProvider.stub = .success(remoteGames)
        
        _ = try await getGames().games
        
        let cachedGames = try cache.retrieveGames()
        
        XCTAssertEqual(cachedGames, remoteGames)
    }
    
    func test_loadMore_withNonEmptyGameCache_deliversAccumulatedGamesFromCacheAndRemote() async throws {
        
        let cachedGames = [
            Game(id: 1, name: "Game 1", imageId: nil),
            Game(id: 2, name: "Game 2", imageId: nil)
        ]
        let cache = Cache(stub: .success(cachedGames))
        let remoteGamesProvider = RemoteGamesProviderStub()
        let getGames = PaginatedGamesProviderAssembler(
            cache: cache,
            remoteGamesProvider: remoteGamesProvider
        ).makeLocalWithRemoteFallbackGamesProvider()
                
        let firstPage = try await getGames()
        
        XCTAssertEqual(firstPage.games.map(\.id), cachedGames.map(\.id))

        let firstBatchOfRemoteGames = [
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
        remoteGamesProvider.stub = .success(firstBatchOfRemoteGames)
        
        let secondPage = try await firstPage.loadMore!()
        
        XCTAssertEqual(secondPage.games.map(\.id), (cachedGames + firstBatchOfRemoteGames).map(\.id))
        
        let secondBatchOfRemoteGames = [
            Game(id: 13, name: "Game 13", imageId: nil),
            Game(id: 14, name: "Game 14", imageId: nil),
            Game(id: 15, name: "Game 15", imageId: nil),
            Game(id: 16, name: "Game 16", imageId: nil),
            Game(id: 17, name: "Game 17", imageId: nil),
            Game(id: 18, name: "Game 18", imageId: nil),
            Game(id: 19, name: "Game 19", imageId: nil),
            Game(id: 20, name: "Game 20", imageId: nil),
            Game(id: 21, name: "Game 21", imageId: nil),
            Game(id: 22, name: "Game 22", imageId: nil)
        ]
        remoteGamesProvider.stub = .success(secondBatchOfRemoteGames)
        
        let thirdPage = try await secondPage.loadMore!()
        
        XCTAssertEqual(thirdPage.games.map(\.id), (cachedGames + firstBatchOfRemoteGames + secondBatchOfRemoteGames).map(\.id))

        let thirdBatchOfRemoteGames = [
            Game(id: 23, name: "Game 23", imageId: nil),
            Game(id: 24, name: "Game 24", imageId: nil)
        ]
        remoteGamesProvider.stub = .success(thirdBatchOfRemoteGames)
        
        let fourthPage = try await thirdPage.loadMore!()
        
        XCTAssertEqual(fourthPage.games.map(\.id), (cachedGames + firstBatchOfRemoteGames + secondBatchOfRemoteGames + thirdBatchOfRemoteGames).map(\.id))
        
        XCTAssertNil(fourthPage.loadMore, "Expected no load more when the last page has been loaded")
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
