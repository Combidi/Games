//
//  Created by Peter Combee on 17/11/2024.
//

struct Paginated {
    let games: [Game]
    let loadMore: (() async throws -> Paginated)?
}
