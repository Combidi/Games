//
//  Created by Peter Combee on 11/11/2024.
//

import Testing

import Foundation

final class HttpClientSpy {
    
    var stub: Error?
    
    private(set) var capturedRequest: URLRequest?
    
    func perform(_ request: URLRequest) throws {
        capturedRequest = request
        try stub.map { throw $0 }
    }
}

struct RemoteGamesProvider {
    private let client: HttpClientSpy
    
    init(client: HttpClientSpy) {
        self.client = client
    }
    
    func getGames() throws {
        let url = URL(string: "https://api.example.com/games")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("Fields name;".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try client.perform(request)
    }
}

struct RemoteGamesProviderTests {

    @Test func getGames_performsPostRequest() throws {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        
        try? sut.getGames()
        
        let request = try #require(client.capturedRequest)
        
        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.example.com/games")!)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.httpBody.map { String(data: $0, encoding: .utf8) }  == "Fields name;")
    }
    
    @Test func getGames_deliversErrorOnClientError() throws {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        client.stub = NSError(domain: "any", code: 0)
        
        #expect(throws: NSError.self) {
            try sut.getGames()
        }
    }
}
