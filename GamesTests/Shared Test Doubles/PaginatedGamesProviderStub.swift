//
//  Created by Peter Combee on 19/11/2024.
//

@testable import Games

final class PaginatedGamesProviderStub: PaginatedGamesProvider {
    var stub: Result<PaginatedGames, Error> = .success(PaginatedGames(games: [], loadMore: nil))
    
    func getGames() throws -> PaginatedGames {
        try stub.get()
    }
}
