//
//  Created by Peter Combee on 19/11/2024.
//

protocol RemoteGamesProvider {
    func getGames(limit: Int, offset: Int) async throws -> [Game]
}
