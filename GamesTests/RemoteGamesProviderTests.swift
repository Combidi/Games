//
//  Created by Peter Combee on 11/11/2024.
//

import XCTest
@testable import Games

final class RemoteGamesProviderTests: XCTestCase {

    private lazy var client = HttpClientSpy()
    private lazy var sut = RemoteGamesProvider(client: client)
    
    func test_getGames_performsPostRequest() async throws {
        _ = try? await sut.getGames()
        
        let request = try XCTUnwrap(client.capturedRequest)
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, URL(string: "https://api.igdb.com/v4/games")!)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.httpBody.map { String(data: $0, encoding: .utf8) }, "f name, cover.image_id;")
    }
    
    func test_getGames_deliversErrorOnClientError() async {
        client.stub = .failure(NSError(domain: "any", code: 0))
        
        do {
            let result = try await sut.getGames()
            XCTFail("Expected error, got \(result) instead")
        } catch {}
    }
    
    func test_getGames_deliversGamesOnValidJsonGamesData() async throws {
        let gamesJson = """
        [
            {
                "id": 131913,
                "cover": {
                    "id": 267633,
                    "image_id": "co5qi9"
                },
                "name": "Maji Kyun! Renaissance"
            },
            {
                "id": 5668,
                "cover": {
                    "id": 119375,
                    "image_id": "co2k3z"
                },
                "name": "Commando"
            },
            {
                "id": 95080,
                "name": "Dotra"
            }
        ]
        """
        client.stub = .success(Data(gamesJson.utf8))
                
        let games = try await sut.getGames()
        
        let expectedGames = [
            Game(id: 131913, name: "Maji Kyun! Renaissance", imageId: "co5qi9"),
            Game(id: 5668, name: "Commando", imageId: "co2k3z"),
            Game(id: 95080, name: "Dotra", imageId: nil)
        ]
        XCTAssertEqual(games.count, 3)
        XCTAssertEqual(games[0], expectedGames[0])
        XCTAssertEqual(games[1], expectedGames[1])
        XCTAssertEqual(games[2], expectedGames[2])
    }
    
    func test_getGames_deliversErrorOnInvalidJsonGamesData() async {
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
