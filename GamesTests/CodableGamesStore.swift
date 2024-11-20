//
//  Created by Peter Combee on 20/11/2024.
//

import XCTest
@testable import Games

private struct CodableGamesStore: GameCacheRetrievable {
    func retrieveGames() -> [Game]? {
        nil
    }
}

final class CodableGamesStoreTests: XCTestCase {
    
    func test_retrieveGames_deliversNilOnEmptyCache() {
        let sut = CodableGamesStore()
    
        XCTAssertNil(sut.retrieveGames())
    }
}
