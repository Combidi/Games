//
//  Created by Peter Combee on 17/11/2024.
//

struct PaginatedGames {
    let games: [Game]
    let loadMore: (() async throws -> PaginatedGames)?
}
