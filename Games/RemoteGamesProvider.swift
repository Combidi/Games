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
        
    func getGames() async throws -> [Game] {
        let url = URL(string: "https://api.igdb.com/v4/games")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("fields name;".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await client.perform(request)
        let decodableGames = try JSONDecoder().decode([DecodableGame].self, from: data)
        let games = decodableGames.map {
            Game(id: $0.id, name: $0.name)
        }
        return games
    }
}
