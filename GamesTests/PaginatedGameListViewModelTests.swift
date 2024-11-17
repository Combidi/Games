//
//  Created by Peter Combee on 15/11/2024.
//

import XCTest
import Combine
@testable import Games

struct PaginatedGames {
    let games: [Game]
    let loadMore: (() async throws -> PaginatedGames)?
}

@MainActor
private final class PaginatedGameListViewModel: ObservableObject {
    
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

@MainActor
final class PaginatedGameListViewModelTests: XCTestCase {
    
    private let loader = LoaderSpy()
    private lazy var sut = PaginatedGameListViewModel(
        loadGames: loader.loadGames,
        reloadGames: loader.reloadGames
    )
    
    func test_load_requestsGames() async {
        XCTAssertEqual(loader.loadGamesCallCount, 0)

        await sut.load()
        
        XCTAssertEqual(loader.loadGamesCallCount, 1)
    }
    
    func test_initialStateIsLoading() {
        XCTAssertEqual(sut.state, .loading)
    }
    
    func test_states_duringLoadingGames() async throws {
        var cancellables: Set<AnyCancellable> = []
        var capturedStates: [PaginatedGameListViewModel.LoadingState] = []
        sut.$state
            .sink { capturedStates.append($0) }
            .store(in: &cancellables)
                
        XCTAssertEqual(
            capturedStates, [.loading],
            "Expected initial state to be .loading"
        )
        
        loader.loadGamesStub = .failure(NSError(domain: "any", code: 0))
        
        await sut.load()
        
        XCTAssertEqual(
            capturedStates,
            [
                .loading,
                .error
            ],
            "Expected error state on loading failure"
        )

        let firstGame = Game(id: 0, name: "Nice game", imageId: nil)
        let secondGame = Game(id: 1, name: "Another game", imageId: nil)
        loader.loadGamesStub = .success([firstGame])
        loader.loadMoreGamesStub = [.success([secondGame])]
        
        await sut.load()

        XCTAssertEqual(
            capturedStates,
            [
                .loading,
                .error,
                .loading,
                .loaded(PresentableGames(games: [firstGame], loadMore: nil))
            ],
            "Expected second .loading state followed by .loaded state after successful loading"
        )
        
        try await presentedPage(sut)?.loadMore?()

        XCTAssertEqual(
            capturedStates,
            [
                .loading,
                .error,
                .loading,
                .loaded(PresentableGames(games: [firstGame], loadMore: nil)),
                .loaded(PresentableGames(games: [firstGame, secondGame], loadMore: nil))
            ],
            "Expected second .loaded state without .loading state after successfully loading more"
        )
    }

    func test_loadMore_loadsMoreUntilEverythingIsLoaded() async throws {
        
        loader.loadGamesStub = .success([
            Game(id: 0, name: "game 0", imageId: "0"),
            Game(id: 1, name: "game 1", imageId: "1")
        ])
        loader.loadMoreGamesStub = [
            .failure(NSError(domain: "any", code: 0)),
            .success([
                Game(id: 2, name: "game 2", imageId: "2"),
                Game(id: 3, name: "game 3", imageId: "3")
            ])
        ]
        
        await sut.load()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                Game(id: 0, name: "game 0", imageId: "0"),
                Game(id: 1, name: "game 1", imageId: "1")
            ],
            "Expected to loaded games to be presented"
        )
        
        try? await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                Game(id: 0, name: "game 0", imageId: "0"),
                Game(id: 1, name: "game 1", imageId: "1"),
            ],
            "Expected presentation state not to be altered after load more failure"
        )
        
        try await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                Game(id: 0, name: "game 0", imageId: "0"),
                Game(id: 1, name: "game 1", imageId: "1"),
                Game(id: 2, name: "game 2", imageId: "2"),
                Game(id: 3, name: "game 3", imageId: "3")
            ],
            "Expected to present all games after successfull load more"
        )
                
        XCTAssertNil(
            presentedPage(sut)?.loadMore,
            "Expected load more to be nil when there are no more pages to load"
        )
    }
    
    func test_reload_requestsGames() async {
        XCTAssertEqual(loader.reloadGamesCallCount, 0)

        await sut.reload()
        
        XCTAssertEqual(loader.reloadGamesCallCount, 1)
    }
    
    func test_states_duringReloadingGames() async {
        await sut.load()
        
        var cancellables: Set<AnyCancellable> = []
        var capturedStates: [PaginatedGameListViewModel.LoadingState] = []
        sut.$state
            .dropFirst()
            .sink { capturedStates.append($0) }
            .store(in: &cancellables)

        
        loader.reloadGamesStub = .failure(NSError(domain: "any", code: 0))
        
        await sut.reload()
        
        XCTAssertEqual(
            capturedStates, [.error],
            "Expected error state on loading failure"
        )

        let game = Game(id: 0, name: "Nice game", imageId: nil)
        loader.reloadGamesStub = .success([game])
        
        await sut.reload()

        let expectedPresentable = PresentableGames(games: [game], loadMore: nil)
        XCTAssertEqual(
            capturedStates, [.error, .loaded(expectedPresentable)],
            "Expected second loading state followed by presentation state after successful loading"
        )
    }

    func test_reload_loadMore_loadsMoreUntilEverythingIsLoaded() async throws {
        
        loader.reloadGamesStub = .success([
            Game(id: 0, name: "game 0", imageId: "0"),
            Game(id: 1, name: "game 1", imageId: "1")
        ])
        loader.loadMoreGamesStub = [
            .failure(NSError(domain: "any", code: 0)),
            .success([
                Game(id: 2, name: "game 2", imageId: "2"),
                Game(id: 3, name: "game 3", imageId: "3")
            ])
        ]
        
        await sut.reload()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                Game(id: 0, name: "game 0", imageId: "0"),
                Game(id: 1, name: "game 1", imageId: "1")
            ],
            "Expected to loaded games to be presented"
        )
        
        try? await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                Game(id: 0, name: "game 0", imageId: "0"),
                Game(id: 1, name: "game 1", imageId: "1"),
            ],
            "Expected presentation state not to be altered after load more failure"
        )
        
        try await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                Game(id: 0, name: "game 0", imageId: "0"),
                Game(id: 1, name: "game 1", imageId: "1"),
                Game(id: 2, name: "game 2", imageId: "2"),
                Game(id: 3, name: "game 3", imageId: "3")
            ],
            "Expected to present all games after successfull load more"
        )
                
        XCTAssertNil(
            presentedPage(sut)?.loadMore,
            "Expected load more to be nil when there are no more pages to load"
        )
    }

    
    // MARK: Helpers
    
    private func presentedGames(_ sut: PaginatedGameListViewModel) -> [Game]? {
        presentedPage(sut)?.games
    }
    
    private func presentedPage(_ sut: PaginatedGameListViewModel) -> PresentableGames? {
        guard case let .loaded(page) = sut.state else {
            return nil
        }
        return page
    }
}


// MARK: Helpers

final private class LoaderSpy {
    private(set) var loadGamesCallCount = 0
    
    var loadGamesStub: Result<[Game], Error> = .success([])
    
    func loadGames() throws -> PaginatedGames {
        loadGamesCallCount += 1
        let games = try loadGamesStub.get()
        return PaginatedGames(
            games: games,
            loadMore: makeLoadMore(currentGames: games)
        )
    }
    
    private(set) var reloadGamesCallCount = 0
    
    var reloadGamesStub: Result<[Game], Error> = .success([])
    
    func reloadGames() throws -> PaginatedGames {
        reloadGamesCallCount += 1
        let games = try reloadGamesStub.get()
        return PaginatedGames(
            games: games,
            loadMore: makeLoadMore(currentGames: games)
        )
    }

    var loadMoreGamesStub: [Result<[Game], Error>] = []

    private func makeLoadMore(currentGames: [Game]) -> (() async throws -> PaginatedGames)? {
        if loadMoreGamesStub.isEmpty { return nil }
        return {
            let nextStub = self.loadMoreGamesStub.removeFirst()
            let games = try currentGames + nextStub.get()
            return PaginatedGames(games: games, loadMore: self.makeLoadMore(currentGames: games))
        }
    }
}
