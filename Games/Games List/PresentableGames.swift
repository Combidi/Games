//
//  Created by Peter Combee on 17/11/2024.
//

struct PresentableGames: Equatable {
    
    let games: [Game]
    let loadMore: (() async throws -> Void)?

    static func == (lhs: Self, rhs: Self) -> Bool {
        rhs.games == lhs.games
    }
}
