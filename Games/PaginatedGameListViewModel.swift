//
//  Created by Peter Combee on 17/11/2024.
//

import Foundation

struct PaginatedGames {
    let games: [Game]
    let loadMore: (() async throws -> PaginatedGames)?
}

@MainActor
final class PaginatedGameListViewModel: ObservableObject {
    
    enum LoadingState: Equatable {
        case loading
        case error
        case loaded(PresentableGames)
    }
    
    private let loadGames: () async throws -> PaginatedGames
    private let reloadGames: () async throws -> PaginatedGames
    
    init(
        loadGames: @escaping () async throws -> PaginatedGames,
        reloadGames: @escaping () async throws -> PaginatedGames
    ) {
        self.loadGames = loadGames
        self.reloadGames = reloadGames
    }
    
    @Published private(set) var state: LoadingState = .loading
    
    func load() async {
        if state != .loading { state = .loading }
        await load(using: loadGames)
    }
    
    func reload() async {
        await load(using: reloadGames)
    }
    
    private func load(using loadAction: () async throws -> PaginatedGames) async {
        do {
            let page = try await loadAction()
            let presentable = PresentableGames(
                games: page.games,
                loadMore: loadNextPage(current: page)
            )
            state = .loaded(presentable)
        }
        catch {
            state = .error
        }
    }
    
    private func loadNextPage(current: PaginatedGames) -> (() async throws -> Void)? {
        guard let loadMore = current.loadMore else { return nil }
        return { [self] in
            let nextPage = try await loadMore()
            let presentable = PresentableGames(
                games: nextPage.games,
                loadMore: loadNextPage(current: nextPage)
            )
            state = .loaded(presentable)
        }
    }
}

struct PresentableGames: Equatable {
    
    let games: [Game]
    let loadMore: (() async throws -> Void)?

    static func == (lhs: Self, rhs: Self) -> Bool {
        rhs.games == lhs.games
    }
}
