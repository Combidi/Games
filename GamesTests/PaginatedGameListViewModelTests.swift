//
//  Created by Peter Combee on 15/11/2024.
//

import XCTest
import Combine
@testable import Games

struct PaginatedGames {
    let games: [Game]
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
            let games = page.games
            let presentable = PresentableGames(games: games)
            state = .loaded(presentable)
        } catch {
            state = .error
        }
    }
    
    func reload() async {
        do {
            let page = try await reloadGames()
            let games = page.games
            let presentable = PresentableGames(games: games)
            
            state = .loaded(presentable)
        } catch {
            state = .error
        }
     }
}

struct PresentableGames: Equatable {
    let games: [Game]
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
    
    func test_states_duringLoadingGames() async {
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

        let game = Game(id: 0, name: "Nice game", imageId: nil)
        loader.loadGamesStub = .success([game])
        
        await sut.load()

        let expectedPresentable = PresentableGames(games: [game])
        XCTAssertEqual(
            capturedStates, [.loading, .error, .loading, .loaded(expectedPresentable)],
            "Expected second loading state followed by presentation state after successful loading"
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

        let expectedPresentable = PresentableGames(games: [game])
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
        return PaginatedGames(games: try loadGamesStub.get())
    }
    
    private(set) var reloadGamesCallCount = 0
    
    var reloadGamesStub: Result<[Game], Error> = .success([])
    
    func reloadGames() throws -> PaginatedGames {
        reloadGamesCallCount += 1
        return PaginatedGames(games: try reloadGamesStub.get())
    }
}
