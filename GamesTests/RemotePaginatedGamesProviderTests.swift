//
//  Created by Peter Combee on 18/11/2024.
//

import XCTest
@testable import Games

private protocol RemoteGamesProvider {
    func getGames(limit: Int, offset: Int) async throws -> [Game]
}

private struct RemotePaginatedGamesProvider {
        
    private let remoteGamesProvider: RemoteGamesProvider
    
    init(remoteGamesProvider: RemoteGamesProvider) {
        self.remoteGamesProvider = remoteGamesProvider
    }
    
    func getGames() async throws -> PaginatedGames {
        let games = try await remoteGamesProvider.getGames(limit: 10, offset: 0)
        return PaginatedGames(games: games, loadMore: nil)
    }
}

final class RemotePaginatedGamesProviderTests: XCTestCase {
    
    func test_getGames_loadsFirstPageFromRemoteLoader() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        
        try await sut.getGames()
        
        XCTAssertEqual(remoteGamesProvider.capturedMessages, [.init(limit: 10, offset: 0)])
    }

    func test_getGames_deliversGamesReceivedFromRemoteLoader() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        let game = Game(id: 0, name: "first", imageId: nil)
        remoteGamesProvider.stub = .success([game])
 
        let result = try await sut.getGames()
        
        XCTAssertEqual(result.games, [game])
    }
}

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
