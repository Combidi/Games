//
//  Created by Peter Combee on 11/11/2024.
//

import Testing

import Foundation

final class HttpClientSpy {
    private(set) var capturedRequest: URLRequest?
    
    func perform(_ request: URLRequest) {
        capturedRequest = request
    }
}

struct RemoteGamesProvider {
    private let client: HttpClientSpy
    
    init(client: HttpClientSpy) {
        self.client = client
    }
    
    func getGames() {
        let url = URL(string: "https://api.example.com/games")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("Fields name;".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        client.perform(request)
    }
}

struct RemoteGamesProviderTests {

    @Test func getGames_performsPostRequest() throws {
        let client = HttpClientSpy()
        let sut = RemoteGamesProvider(client: client)
        
        sut.getGames()
        
        let request = try #require(client.capturedRequest)
        
        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.example.com/games")!)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.httpBody.map { String(data: $0, encoding: .utf8) }  == "Fields name;")
    }
}
