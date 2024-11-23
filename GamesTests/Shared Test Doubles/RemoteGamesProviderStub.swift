//
//  Created by Peter Combee on 23/11/2024.
//

@testable import Games

final class RemoteGamesProviderStub: RemoteGamesProvider {
            
    var stub: Result<[Game], Error> = .success([])
    
    func getGames(limit: Int, offset: Int) async throws -> [Game] {
        return try stub.get()
    }
}
