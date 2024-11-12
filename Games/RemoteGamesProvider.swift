//
//  Created by Peter Combee on 12/11/2024.
//

import Foundation

struct RemoteGamesProvider {

    private struct DecodableGame: Decodable {
        let id: Int
        let name: String
    }

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
        let decodableGames = try JSONDecoder().decode([DecodableGame].self, from: data)
        let games = decodableGames.map {
            Game(id: $0.id, name: $0.name)
        }
        return games
    }
}
