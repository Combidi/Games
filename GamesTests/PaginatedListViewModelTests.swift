//
//  Created by Peter Combee on 15/11/2024.
//

import XCTest
import Combine
@testable import Games

@MainActor
final class PaginatedListViewModelTests: XCTestCase {
    
    typealias SUT = PaginatedListViewModel<Game>
    
    private let loader = LoaderSpy()
    private lazy var sut = SUT(
        load: loader.loadGames,
        reload: loader.reloadGames
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
        var capturedStates: [SUT.LoadingState] = []
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

        let firstGame = makeGame(id: 0)
        let secondGame = makeGame(id: 1)
        loader.loadGamesStub = .success([firstGame])
        loader.loadMoreGamesStub = [.success([secondGame])]
        
        await sut.load()

        XCTAssertEqual(
            capturedStates,
            [
                .loading,
                .error,
                .loading,
                .loaded(.init(items: [firstGame], loadMore: nil))
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
                .loaded(.init(items: [firstGame], loadMore: nil)),
                .loaded(.init(items: [firstGame, secondGame], loadMore: nil))
            ],
            "Expected second .loaded state without .loading state after successfully loading more"
        )
    }

    func test_loadMore_loadsMoreUntilEverythingIsLoaded() async throws {
        
        loader.loadGamesStub = .success([
            makeGame(id: 1),
            makeGame(id: 2)
        ])
        loader.loadMoreGamesStub = [
            .failure(NSError(domain: "any", code: 0)),
            .success([
                makeGame(id: 3),
                makeGame(id: 4)
            ])
        ]
        
        await sut.load()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                makeGame(id: 1),
                makeGame(id: 2)
            ],
            "Expected to loaded games to be presented"
        )
        
        try? await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                makeGame(id: 1),
                makeGame(id: 2)
            ],
            "Expected presentation state not to be altered after load more failure"
        )
        
        try await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                makeGame(id: 1),
                makeGame(id: 2),
                makeGame(id: 3),
                makeGame(id: 4)
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
        var capturedStates: [SUT.LoadingState] = []
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

        let game = makeGame(id: 0)
        loader.reloadGamesStub = .success([game])
        
        await sut.reload()

        let expectedPresentable = SUT.Presentable(items: [game], loadMore: nil)
        XCTAssertEqual(
            capturedStates, [.error, .loaded(expectedPresentable)],
            "Expected second loading state followed by presentation state after successful loading"
        )
    }

    func test_reload_loadMore_loadsMoreUntilEverythingIsLoaded() async throws {
        
        loader.reloadGamesStub = .success([
            makeGame(id: 0),
            makeGame(id: 1),
        ])
        loader.loadMoreGamesStub = [
            .failure(NSError(domain: "any", code: 0)),
            .success([
                makeGame(id: 2),
                makeGame(id: 3)
            ])
        ]
        
        await sut.reload()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                makeGame(id: 0),
                makeGame(id: 1),
            ],
            "Expected to loaded games to be presented"
        )
        
        try? await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                makeGame(id: 0),
                makeGame(id: 1),
            ],
            "Expected presentation state not to be altered after load more failure"
        )
        
        try await presentedPage(sut)?.loadMore?()
        
        XCTAssertEqual(
            presentedGames(sut),
            [
                makeGame(id: 0),
                makeGame(id: 1),
                makeGame(id: 2),
                makeGame(id: 3)
            ],
            "Expected to present all games after successfull load more"
        )
                
        XCTAssertNil(
            presentedPage(sut)?.loadMore,
            "Expected load more to be nil when there are no more pages to load"
        )
    }

    
    // MARK: Helpers
    
    private func presentedGames(_ sut: PaginatedListViewModel<Game>) -> [Game]? {
        presentedPage(sut)?.items
    }
    
    private func presentedPage(_ sut: PaginatedListViewModel<Game>) -> PresentableListItems<Game>? {
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
    
    func loadGames() throws -> Paginated<Game> {
        loadGamesCallCount += 1
        let games = try loadGamesStub.get()
        return Paginated(
            items: games,
            loadMore: makeLoadMore(currentGames: games)
        )
    }
    
    private(set) var reloadGamesCallCount = 0
    
    var reloadGamesStub: Result<[Game], Error> = .success([])
    
    func reloadGames() throws -> Paginated<Game> {
        reloadGamesCallCount += 1
        let games = try reloadGamesStub.get()
        return Paginated(
            items: games,
            loadMore: makeLoadMore(currentGames: games)
        )
    }

    var loadMoreGamesStub: [Result<[Game], Error>] = []

    private func makeLoadMore(currentGames: [Game]) -> (() async throws -> Paginated<Game>)? {
        if loadMoreGamesStub.isEmpty { return nil }
        return {
            let nextStub = self.loadMoreGamesStub.removeFirst()
            let games = try currentGames + nextStub.get()
            return Paginated(items: games, loadMore: self.makeLoadMore(currentGames: games))
        }
    }
}
