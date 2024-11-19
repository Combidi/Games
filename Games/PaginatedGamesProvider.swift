//
//  Created by Peter Combee on 19/11/2024.
//

protocol PaginatedGamesProvider {
    func getGames() async throws -> PaginatedGames
}
