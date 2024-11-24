//
//  Created by Peter Combee on 17/11/2024.
//

import Foundation

@MainActor
final class PaginatedGameListViewModel: ObservableObject {
    
    enum LoadingState: Equatable {
        case loading
        case error
        case loaded(PresentableGames)
    }
    
    private let loadGames: () async throws -> Paginated
    private let reloadGames: () async throws -> Paginated
    
    init(
        loadGames: @escaping () async throws -> Paginated,
        reloadGames: @escaping () async throws -> Paginated
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
    
    private func load(using loadAction: () async throws -> Paginated) async {
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
    
    private func loadNextPage(current: Paginated) -> (() async throws -> Void)? {
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
