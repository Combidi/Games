//
//  Created by Peter Combee on 23/11/2024.
//

@testable import Games

final class GamesCacheStub: GamesCache {
                   
    var stub: Result<[Game], Error> = .success([])
    
    func retrieveGames() throws -> [Game] {
        try stub.get()
    }
    
    func store(games: [Game]) throws {
        self.stub = .success(games)
    }
}
