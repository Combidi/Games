//
//  Created by Peter Combee on 18/11/2024.
//

import XCTest
@testable import Games

final class RemotePaginatedGamesProviderTests: XCTestCase {
    
    func test_getGames_loadsFirstPageFromRemoteLoader() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        
        _ = try await sut.getGames()
        
        XCTAssertEqual(remoteGamesProvider.capturedMessages, [.init(limit: 10, offset: 0)])
    }

    func test_getGames_withStartOffset_requestsGamesStartingFromGivenOffset() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(
            startOffset: 30,
            remoteGamesProvider: remoteGamesProvider
        )
        
        _ = try await sut.getGames()
        
        XCTAssertEqual(remoteGamesProvider.capturedMessages, [.init(limit: 10, offset: 30)])
    }
    
    func test_getGames_deliversErrorOnRemoteLoaderError() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        let remoteLoaderError = NSError(domain: "any", code: 1)
        remoteGamesProvider.stub = .failure(remoteLoaderError)
        
        await assertThrowsAsyncError(try await sut.getGames()) { error in
            XCTAssertEqual(error as NSError, remoteLoaderError)
        }
    }
    
    func test_getGames_deliversGamesReceivedFromRemoteLoader() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        let game = Game(id: 0, name: "first", imageId: nil)
        remoteGamesProvider.stub = .success([game])
        let result = try await sut.getGames()
        
        XCTAssertEqual(result.games, [game])
    }
    
    func test_loadMore_loadsNextPageFromRemoteLoader() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        remoteGamesProvider.stub = .success(Array(repeating: Game(id: 0, name: "any", imageId: nil), count: 10))
        
        let firstPage = try await sut.getGames()

        XCTAssertEqual(
            remoteGamesProvider.capturedMessages,
            [
                .init(limit: 10, offset: 0)
            ]
        )

        let secondPage = try await firstPage.loadMore!()
        
        XCTAssertEqual(
            remoteGamesProvider.capturedMessages,
            [
                .init(limit: 10, offset: 0),
                .init(limit: 10, offset: 10),
            ]
        )

        let _ = try await secondPage.loadMore!()

        XCTAssertEqual(
            remoteGamesProvider.capturedMessages,
            [
                .init(limit: 10, offset: 0),
                .init(limit: 10, offset: 10),
                .init(limit: 10, offset: 20)
            ]
        )
    }
    
    func test_loadMore_withStartOffset_loadsNextPageFromRemoteLoader() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(
            startOffset: 15,
            remoteGamesProvider: remoteGamesProvider
        )
        remoteGamesProvider.stub = .success(Array(repeating: Game(id: 0, name: "any", imageId: nil), count: 10))
        
        let firstPage = try await sut.getGames()

        XCTAssertEqual(
            remoteGamesProvider.capturedMessages,
            [
                .init(limit: 10, offset: 15)
            ]
        )

        let secondPage = try await firstPage.loadMore!()
        
        XCTAssertEqual(
            remoteGamesProvider.capturedMessages,
            [
                .init(limit: 10, offset: 15),
                .init(limit: 10, offset: 25),
            ]
        )

        let _ = try await secondPage.loadMore!()

        XCTAssertEqual(
            remoteGamesProvider.capturedMessages,
            [
                .init(limit: 10, offset: 15),
                .init(limit: 10, offset: 25),
                .init(limit: 10, offset: 35)
            ]
        )
    }

    func test_loadMore_deliversErrorOnRemoteLoaderError() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        remoteGamesProvider.stub = .success(Array(repeating: Game(id: 0, name: "any", imageId: nil), count: 10))
        let firstPage = try await sut.getGames()

        let remoteLoaderError = NSError(domain: "any", code: 1)
        remoteGamesProvider.stub = .failure(remoteLoaderError)
        
        await assertThrowsAsyncError(try await firstPage.loadMore!()) { error in
            XCTAssertEqual(error as NSError, remoteLoaderError)
        }
    }
    
    func test_loadMore_deliversNextPageContainingAccumulatedGames() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        let firstBatchOfGames = Array(repeating: Game(id: 0, name: "first", imageId: nil), count: 10)
        remoteGamesProvider.stub = .success(firstBatchOfGames)
        
        let firstPage = try await sut.getGames()
        
        XCTAssertEqual(
            firstPage.games,
            firstBatchOfGames
        )
        
        let secondBatchOfGames = Array(repeating: Game(id: 0, name: "second", imageId: nil), count: 10)
        remoteGamesProvider.stub = .success(secondBatchOfGames)

        let secondPage = try await firstPage.loadMore?()
        
        XCTAssertEqual(
            secondPage?.games,
            firstBatchOfGames + secondBatchOfGames
        )

        let thirdBatchOfGames = Array(repeating: Game(id: 0, name: "third", imageId: nil), count: 10)
        remoteGamesProvider.stub = .success(thirdBatchOfGames)
        
        let thirdPage = try await secondPage?.loadMore?()

        XCTAssertEqual(
            thirdPage?.games,
            firstBatchOfGames + secondBatchOfGames + thirdBatchOfGames
        )
    }
    
    func test_doesNotProvideLoadMoreClosure_onceAllPagesHaveBeenLoaded() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        let firstBatchOfGames = Array(repeating: Game(id: 0, name: "first", imageId: nil), count: 10)
        remoteGamesProvider.stub = .success(firstBatchOfGames)
        
        let firstPage = try await sut.getGames()
        
        let secondBatchOfGames = Array(repeating: Game(id: 0, name: "second", imageId: nil), count: 9)
        remoteGamesProvider.stub = .success(secondBatchOfGames)

        let secondPage = try await firstPage.loadMore?()

        XCTAssertNil(secondPage?.loadMore, "Expected no load more closure")
    }
}

// MARK: - Helpers

private final class RemoteGamesProviderSpy: RemoteGamesProvider {
        
    struct Message: Equatable {
        let limit: Int
        let offset: Int
    }
    
    var stub: Result<[Game], Error> = .success([])
    
    private(set) var capturedMessages: [Message] = []
    
    func getGames(limit: Int, offset: Int) async throws -> [Game] {
        capturedMessages.append(Message(limit: limit, offset: offset))
        return try stub.get()
    }
}
