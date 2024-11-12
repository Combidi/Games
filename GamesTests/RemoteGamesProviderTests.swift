//
//  Created by Peter Combee on 11/11/2024.
//

import XCTest
@testable import Games

final class RemoteGamesProviderTests: XCTestCase {
    
    func test_getGames_performsPostRequest() throws {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        
        _ = try? sut.getGames()
        
        let request = try XCTUnwrap(client.capturedRequest)
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, URL(string: "https://api.example.com/games")!)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.httpBody.map { String(data: $0, encoding: .utf8) }, "Fields name;")
    }
    
    func test_getGames_deliversErrorOnClientError() {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        client.stub = .failure(NSError(domain: "any", code: 0))
        
        XCTAssertThrowsError(try sut.getGames())
    }
    
    func test_getGames_deliversGamesOnValidJsonGamesData() throws {
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
        
        let games = try sut.getGames()
        XCTAssertEqual(games, expectedGames)
    }
    
    func test_getGames_deliversErrorOnInvalidJsonGamesData() {
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
        
        XCTAssertThrowsError(try sut.getGames())
    }
}

// MARK: - Helpers

private final class HttpClientSpy: HttpClient {
    
    var stub: Result<Data, Error> = .success(Data())
    
    private(set) var capturedRequest: URLRequest?
    
    func perform(_ request: URLRequest) throws -> Data {
        capturedRequest = request
        return try stub.get()
    }
}
