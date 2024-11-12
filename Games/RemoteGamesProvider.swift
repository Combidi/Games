//
//  Created by Peter Combee on 12/11/2024.
//

import Foundation

protocol HttpClient {
    func perform(_ request: URLRequest) throws -> Data
}

struct RemoteGamesProvider {
    private let client: HttpClient
    
    init(client: HttpClient) {
        self.client = client
    }
        
    func getGames() throws -> [Game] {
        let url = URL(string: "https://api.example.com/games")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("Fields name;".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data = try client.perform(request)
        let games = try JSONDecoder().decode([Game].self, from: data)
        return games
    }
}
