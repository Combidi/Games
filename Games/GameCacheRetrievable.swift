//
//  Created by Peter Combee on 23/11/2024.
//

protocol GameCacheRetrievable {
    func retrieveGames() throws -> [Game]
}
