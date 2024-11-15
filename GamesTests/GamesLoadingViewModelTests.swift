//
//  Created by Peter Combee on 15/11/2024.
//

import XCTest
import Combine
@testable import Games

final class GamesLoadingViewModel {
    
    enum LoadingState: Equatable {
        case loading
        case error
        case loaded([Game])
    }
    
    private let loadGames: () throws -> [Game]
    private let reloadGames: () -> Void
    init(
        loadGames: @escaping () throws -> [Game],
        reloadGames: @escaping () -> Void
    ) {
        self.loadGames = loadGames
        self.reloadGames = reloadGames
    }
    
    @Published private(set) var state: LoadingState = .loading
    
    func load() {
        if state != .loading { state = .loading }
        do {
            let games = try loadGames()
            state = .loaded(games)
        } catch {
            state = .error
        }
    }
    
    func reload() {
        reloadGames()
    }
}

final class GamesLoadingViewModelTests: XCTestCase {
    
    private let loader = LoaderSpy()
    private lazy var sut = GamesLoadingViewModel(
        loadGames: loader.loadGames,
        reloadGames: loader.reloadGames
    )
    
    func test_load_requestsGames() {
        XCTAssertEqual(loader.loadGamesCallCount, 0)

        sut.load()
        
        XCTAssertEqual(loader.loadGamesCallCount, 1)
    }
    
    func test_initialStateIsLoading() {
        XCTAssertEqual(sut.state, .loading)
    }
    
    func test_states_duringLoadingGames() {
        var cancellables: Set<AnyCancellable> = []
        var capturedStates: [GamesLoadingViewModel.LoadingState] = []
        sut.$state
            .sink { capturedStates.append($0) }
            .store(in: &cancellables)
                
        XCTAssertEqual(
            capturedStates, [.loading],
            "Expected initial state to be .loading"
        )
        
        loader.loadGamesStub = .failure(NSError(domain: "any", code: 0))
        
        sut.load()
        
        XCTAssertEqual(
            capturedStates, [.loading, .error],
            "Expected error state on loading failure"
        )

        let game = Game(id: 0, name: "Nice game", imageId: nil)
        loader.loadGamesStub = .success([game])
        
        sut.load()

        XCTAssertEqual(
            capturedStates, [.loading, .error, .loading, .loaded([game])],
            "Expected second loading state followed by presentation state after successful loading"
        )
    }

    func test_reload_requestsGames() {
        XCTAssertEqual(loader.reloadGamesCallCount, 0)

        sut.reload()
        
        XCTAssertEqual(loader.reloadGamesCallCount, 1)
    }
}

// MARK: Helpers

final private class LoaderSpy {
    private(set) var loadGamesCallCount = 0
    
    var loadGamesStub: Result<[Game], Error> = .success([])
    
    func loadGames() throws -> [Game] {
        loadGamesCallCount += 1
        return try loadGamesStub.get()
    }
    
    private(set) var reloadGamesCallCount = 0
    
    func reloadGames() {
        reloadGamesCallCount += 1
    }
}
