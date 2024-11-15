//
//  Created by Peter Combee on 15/11/2024.
//

import XCTest

final class GamesLoadingViewModel {
    
    enum LoadingState {
        case loading
    }
    
    private let loadGames: () -> Void
    
    init(loadGames: @escaping () -> Void) {
        self.loadGames = loadGames
    }
    
    let state: LoadingState = .loading
    
    func load() {
        loadGames()
    }
}

final class GamesLoadingViewModelTests: XCTestCase {
    
    func test_load_requestsGames() {
        let loader = LoaderSpy()
        let sut = GamesLoadingViewModel(loadGames: loader.loadGames)
    
        XCTAssertEqual(loader.loadGamesCallCount, 0)

        sut.load()
        
        XCTAssertEqual(loader.loadGamesCallCount, 1)
    }
    
    func test_initialStateIsLoading() {
        let sut = GamesLoadingViewModel(loadGames: { })
        
        XCTAssertEqual(sut.state, .loading)
    }
}

// MARK: Helpers

final private class LoaderSpy {
    private(set) var loadGamesCallCount = 0
    
    func loadGames() {
        loadGamesCallCount += 1
    }
}
