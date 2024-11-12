//
//  Created by Peter Combee on 11/11/2024.
//

import XCTest
@testable import Games

final class RemoteGamesProviderTests: XCTestCase {
    
    func test_getGames_performsPostRequest() async throws {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        
        _ = try? await sut.getGames()
        
        let request = try XCTUnwrap(client.capturedRequest)
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, URL(string: "https://api.igdb.com/v4/games")!)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.httpBody.map { String(data: $0, encoding: .utf8) }, "fields name;")
    }
    
    func test_getGames_deliversErrorOnClientError() async {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        client.stub = .failure(NSError(domain: "any", code: 0))
        
        do {
            let result = try await sut.getGames()
            XCTFail("Expected error, got \(result) instead")
        } catch {}
    }
    
    func test_getGames_deliversGamesOnValidJsonGamesData() async throws {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        let gamesJson = """
        [
          {
            "id": 131913,
            "name": "Maji Kyun! Renaissance"
          },
          {
            "id": 5668,
            "name": "Commando"
          },
          {
            "id": 95080,
            "name": "Dotra"
          }
        ]
        """
        client.stub = .success(Data(gamesJson.utf8))
        
        let expectedGames = [
            Game(id: 131913, name: "Maji Kyun! Renaissance"),
            Game(id: 5668, name: "Commando"),
            Game(id: 95080, name: "Dotra")
        ]
        
        let games = try await sut.getGames()
        XCTAssertEqual(games, expectedGames)
    }
    
    func test_getGames_deliversErrorOnInvalidJsonGamesData() async {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        let gamesJson = """
        [
          {
            "id": 131913
          },
          {
            "name": "Commando"
          },
          {
            "id": 95080,
            "name": "Dotra"
          }
        ]
        """
        client.stub = .success(Data(gamesJson.utf8))
        
        do {
            let result = try await sut.getGames()
            XCTFail("Expected error, got \(result) instead")
        } catch {}
    }
}
