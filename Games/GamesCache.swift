//
//  Created by Peter Combee on 23/11/2024.
//

protocol GamesCache {
    func retrieveGames() throws -> [Game]
    func store(games: [Game]) throws
}
