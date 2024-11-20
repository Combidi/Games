//
//  Created by Peter Combee on 20/11/2024.
//

import XCTest
@testable import Games

private struct CodableGamesStore: GameCacheRetrievable, GameCacheStorable {
        
    private let storeUrl: URL
    
    init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    func retrieveGames() throws -> [Game]? {
        guard let data = try? Data(contentsOf: storeUrl) else { return nil }
        return try JSONDecoder().decode([Game].self, from: data)
    }
    
    func store(games: [Game]) {
        let encoded = try! JSONEncoder().encode(games)
        try! encoded.write(to: storeUrl)
    }
}

final class CodableGamesStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    override func tearDown() {
        super.tearDown()

        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    func test_retrieveGames_deliversNilOnEmptyCache() {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)
    
        XCTAssertNil(try! sut.retrieveGames())
    }
    
    func test_retrieveGames_test_deliversFoundValuesOnNonEmptyCache() throws {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)
        let games = [Game(id: 1, name: "nice game", imageId: nil)]
        
        sut.store(games: games)
        
        let retrievedGames = try sut.retrieveGames()
        
        XCTAssertEqual(retrievedGames, games)
    }
    
    func test_retrieveGames_deliversErrorOnRetrievalError() {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)

        try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
     
        XCTAssertThrowsError(try sut.retrieveGames())
    }
    
    private var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
