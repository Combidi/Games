//
//  Created by Peter Combee on 19/11/2024.
//

struct RemotePaginatedGamesProvider: PaginatedGamesProvider {
        
    private let remoteGamesProvider: RemoteGamesProvider
    
    init(remoteGamesProvider: RemoteGamesProvider) {
        self.remoteGamesProvider = remoteGamesProvider
    }
    
    func getGames() async throws -> PaginatedGames {
        let games = try await remoteGamesProvider.getGames(limit: 10, offset: 0)
        return PaginatedGames(games: games, loadMore: makeRemoteLoadMoreLoader(currentGames: games))
    }
    
    private func makeRemoteLoadMoreLoader(currentGames: [Game]) -> () async throws -> PaginatedGames {
        return {
            let nextBatchOfGames = try await remoteGamesProvider.getGames(
                limit: 10,
                offset: currentGames.count
            )
            let reachedEnd = nextBatchOfGames.count != 10
            let games = currentGames + nextBatchOfGames
            let page =  PaginatedGames(
                games: games,
                loadMore: reachedEnd ? nil : makeRemoteLoadMoreLoader(currentGames: games)
            )
            return page
        }
    }
}
