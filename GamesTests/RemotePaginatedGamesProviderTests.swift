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
    
    func getGames() async throws {
        try await _ = remoteGamesProvider.getGames(limit: 10, offset: 0)
    }
}

final class RemotePaginatedGamesProviderTests: XCTestCase {
    
    func test_getGames_loadsFirstPage() async throws {
        let remoteGamesProvider = RemoteGamesProviderSpy()
        let sut = RemotePaginatedGamesProvider(remoteGamesProvider: remoteGamesProvider)
        
        try await sut.getGames()
        
        XCTAssertEqual(remoteGamesProvider.capturedMessages, [.init(limit: 10, offset: 0)])
    }
}

private final class RemoteGamesProviderSpy: RemoteGamesProvider {
        
    struct Message: Equatable {
        let limit: Int
        let offset: Int
    }
    
    private(set) var capturedMessages: [Message] = []
    
    func getGames(limit: Int, offset: Int) async throws -> [Game] {
        capturedMessages.append(Message(limit: limit, offset: offset))
        return []
    }
}
