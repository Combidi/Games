//
//  Created by Peter Combee on 15/11/2024.
//

import XCTest

final class GamesLoadingViewModel {
    
    private let loadGames: () -> Void
    
    init(loadGames: @escaping () -> Void) {
        self.loadGames = loadGames
    }
    
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
}

// MARK: Helpers

final private class LoaderSpy {
    private(set) var loadGamesCallCount = 0
    
    func loadGames() {
        loadGamesCallCount += 1
    }
}
