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
    
    private func makeSUT(storeUrl: URL = testSpecificStoreURL) -> CodableGamesStore {
        CodableGamesStore(storeUrl: storeUrl)
    }
    
    func test_retrieveGames_deliversEmptyGamesOnEmptyCache() {
        XCTAssertEqual(try! makeSUT().retrieveGames(), [])
    }
    
    func test_retrieveGames_test_deliversFoundValuesOnNonEmptyCache() throws {
        let sut = makeSUT()
        let games = [
            Game(
                id: 1,
                name: "Nice game",
                imageId: "any-image-id",
                rating: 2.2,
                description: "What a game...."
            )
        ]
        
        try sut.store(games: games)
        
        let retrievedGames = try sut.retrieveGames()
        
        XCTAssertEqual(retrievedGames, games)
    }
    
    func test_retrieveGames_deliversErrorOnRetrievalError() {
        let sut = makeSUT(storeUrl: testSpecificStoreURL)

        try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
     
        XCTAssertThrowsError(try makeSUT().retrieveGames())
    }
    
    func test_storeGames_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        let games = [makeGame(id: 1)]

        XCTAssertNoThrow(try sut.store(games: games))
    }

    func test_storeGames_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        let games = [makeGame(id: 1)]

        XCTAssertNoThrow(try sut.store(games: games))
        XCTAssertNoThrow(try sut.store(games: games))
    }
    
    func test_storeGames_overridesPreviouslyInsertedCacheValues() throws {
        let sut = makeSUT()
        let firstGame = Game(
            id: 1,
            name: "Nice game",
            imageId: "any-image-id",
            rating: 2.2,
            description: "What a game...."
        )

        try sut.store(games: [firstGame])
        
        let secondGame = Game(
            id: 2,
            name: "Even better game",
            imageId: "another-image-id",
            rating: 3.2,
            description: "Meh?"
        )

        try sut.store(games: [secondGame])

        XCTAssertEqual(try sut.retrieveGames(), [secondGame])
    }
    
    func test_storeGames_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeUrl: invalidStoreURL)

        XCTAssertThrowsError(try sut.store(games: [makeGame()]))
    }
    
    func test_storedGames_persistsBetweenSessions() throws {
        let games = [
            makeGame(id: 1),
            makeGame(id: 2)
        ]

        let sutToInsert = makeSUT()
        try sutToInsert.store(games: games)

        let sutToRetrieve = makeSUT()
        let retrievedGames = try sutToRetrieve.retrieveGames()

        XCTAssertEqual(retrievedGames, games)
    }
}

private var testSpecificStoreURL: URL {
    FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("CodableGamesStoreTests.store")
}
