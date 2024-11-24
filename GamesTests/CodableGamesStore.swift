//
//  Created by Peter Combee on 20/11/2024.
//

import XCTest
@testable import Games

final class CodableGamesStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    override func tearDown() {
        super.tearDown()

        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    func test_retrieveGames_deliversEmptyGamesOnEmptyCache() {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)
    
        XCTAssertEqual(try! sut.retrieveGames(), [])
    }
    
    func test_retrieveGames_test_deliversFoundValuesOnNonEmptyCache() throws {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)
        let games = [
            Game(
                id: 1,
                name: "Nice game",
                imageId: "any-image-id",
                rating: nil,
                description: nil
            )
        ]
        
        try sut.store(games: games)
        
        let retrievedGames = try sut.retrieveGames()
        
        XCTAssertEqual(retrievedGames, games)
    }
    
    func test_retrieveGames_deliversErrorOnRetrievalError() {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)

        try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
     
        XCTAssertThrowsError(try sut.retrieveGames())
    }
    
    func test_storeGames_deliversNoErrorOnEmptyCache() {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)
        let games = [makeGame(id: 1)]

        XCTAssertNoThrow(try sut.store(games: games))
    }

    func test_storeGames_deliversNoErrorOnNonEmptyCache() {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)
        let games = [makeGame(id: 1)]

        XCTAssertNoThrow(try sut.store(games: games))
        XCTAssertNoThrow(try sut.store(games: games))
    }
    
    func test_storeGames_overridesPreviouslyInsertedCacheValues() throws {
        let sut = CodableGamesStore(storeUrl: testSpecificStoreURL)
        let firstGame = makeGame(id: 1)

        try sut.store(games: [firstGame])
        
        let secondGame = makeGame(id: 2)
        try sut.store(games: [secondGame])

        XCTAssertEqual(try sut.retrieveGames(), [secondGame])
    }
    
    func test_storeGames_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = CodableGamesStore(storeUrl: invalidStoreURL)

        XCTAssertThrowsError(try sut.store(games: [makeGame()]))
    }
    
    func test_storedGames_persistsBetweenSessions() throws {
        let games = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]

        let sutToInsert = CodableGamesStore(storeUrl: testSpecificStoreURL)
        try sutToInsert.store(games: games)

        let sutToRetrieve = CodableGamesStore(storeUrl: testSpecificStoreURL)
        let retrievedGames = try sutToRetrieve.retrieveGames()

        XCTAssertEqual(retrievedGames, games)
    }
    
    private var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
