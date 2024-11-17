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
        do {
            let page = try await loadGames()
            let presentable = PresentableGames(
                games: page.games,
                loadMore: loadNextPage(current: page)
            )
            state = .loaded(presentable)
        }
        catch { state = .error }
    }
    
    private func loadNextPage(current: PaginatedGames) -> (() async throws -> Void)? {
        guard let loadMore = current.loadMore else { return nil }
        return {
            let nextPage = try await loadMore()
            let presentable = PresentableGames(
                games: nextPage.games,
                loadMore: self.loadNextPage(current: nextPage)
            )
            self.state = .loaded(presentable)
        }
    }
    
    func reload() async {
        do {
            let page = try await reloadGames()
            let games = page.games
            let presentable = PresentableGames(games: games, loadMore: nil)
            
            state = .loaded(presentable)
        } catch {
            state = .error
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
            capturedStates, [.loading, .error],
            "Expected error state on loading failure"
        )

        let firstGame = Game(id: 0, name: "Nice game", imageId: nil)
        let secondGame = Game(id: 1, name: "Another game", imageId: nil)
        loader.loadGamesStub = .success([firstGame])
        loader.loadMoreGamesStub = [.success([secondGame])]
        
        await sut.load()

        let firstExpectedPresentable = PresentableGames(games: [firstGame], loadMore: nil)
        XCTAssertEqual(
            capturedStates, [.loading, .error, .loading, .loaded(firstExpectedPresentable)],
            "Expected second loading state followed by presentation state after successful loading"
        )
        
        guard case let .loaded(firstPage) = sut.state else {
            return XCTFail()
        }

        try await firstPage.loadMore!()
        let secondExpectedPresentable = PresentableGames(games: [firstGame, secondGame], loadMore: nil)
        XCTAssertEqual(
            capturedStates, [.loading, .error, .loading, .loaded(firstExpectedPresentable), .loaded(secondExpectedPresentable)],
            "Expected second loading state followed by presentation state after successful loading"
        )
    }

    func test_loadMore_loadsModeUntilEvetythingIsLoaded() async {
        
        loader.loadGamesStub = .success([
            Game(id: 0, name: "game 0", imageId: "0"),
            Game(id: 1, name: "game 1", imageId: "1")
        ])
        
        loader.loadMoreGamesStub = [
            .success([
                Game(id: 2, name: "game 2", imageId: "2"),
                Game(id: 3, name: "game 3", imageId: "3")
            ]),
            .failure(NSError(domain: "any", code: 0)),
            .success([
                Game(id: 4, name: "game 4", imageId: "4"),
                Game(id: 5, name: "game 5", imageId: "5"),
                Game(id: 6, name: "game 6", imageId: "6")
            ])
        ]
        
        await sut.load()
        
        guard case let .loaded(firstPage) = sut.state else {
            return XCTFail()
        }
        
        XCTAssertEqual(firstPage.games, [
            Game(id: 0, name: "game 0", imageId: "0"),
            Game(id: 1, name: "game 1", imageId: "1")
        ])
        
        try? await firstPage.loadMore?()
        
        guard case let .loaded(secondPage) = sut.state else {
            return XCTFail()
        }
        
        XCTAssertEqual(secondPage.games, [
            Game(id: 0, name: "game 0", imageId: "0"),
            Game(id: 1, name: "game 1", imageId: "1"),
            Game(id: 2, name: "game 2", imageId: "2"),
            Game(id: 3, name: "game 3", imageId: "3")
        ])
        
        try? await secondPage.loadMore?()
        try? await secondPage.loadMore?() // This one is the failure....
        
        guard case let .loaded(thirdPage) = sut.state else {
            return XCTFail()
        }
        
        XCTAssertEqual(thirdPage.games, [
            Game(id: 0, name: "game 0", imageId: "0"),
            Game(id: 1, name: "game 1", imageId: "1"),
            Game(id: 2, name: "game 2", imageId: "2"),
            Game(id: 3, name: "game 3", imageId: "3"),
            Game(id: 4, name: "game 4", imageId: "4"),
            Game(id: 5, name: "game 5", imageId: "5"),
            Game(id: 6, name: "game 6", imageId: "6")
        ])
        
        XCTAssertNil(thirdPage.loadMore)
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
