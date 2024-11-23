//
//  Created by Peter Combee on 23/11/2024.
//

@testable import Games

final class GamesCacheStub: GamesCache {
            
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
