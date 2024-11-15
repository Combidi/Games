//
//  Created by Peter Combee on 15/11/2024.
//

import SwiftUI

struct GamesLoadingView: View {

    enum LoadingState {
        case loading
        case loaded([Game])
        case error
    }
    
    private let loadGames: () async throws -> [Game]
    private let reloadGames: () async throws -> [Game]

    init(
        loadGames: @escaping () async throws -> [Game],
        reloadGames: @escaping () async throws -> [Game]
    ) {
        self.loadGames = loadGames
        self.reloadGames = reloadGames
    }
    
    @State private var state: LoadingState = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                Text("Loading...")
                
            case .loaded(let games):
                listView(for: games)

            case .error:
                Text("Oeps, something went wrong.")
                
            }
        }
        .task { await load() }
    }
    
    private func listView(for games: [Game]) -> some View {
        List(games, id: \.id) { game in
            GameListItemView(
                imageUrl: imageUrl(for: game.imageId),
                name: game.name
            )
            .listRowSeparator(.hidden)
        }
        .refreshable(action: { await reload() })
    }
    
    private func load() async {
        state = .loading
        do {
            let games = try await loadGames()
            state = .loaded(games)
        } catch {
            state = .error
        }
    }
    
    private func reload() async {
        do {
            let games = try await reloadGames()
            state = .loaded(games)
        } catch {
            state = .error
        }
    }
    
    private func imageUrl(for imageId: String?) -> URL? {
        guard
            let imageId = imageId,
            let imageUrl = URL(string: "https://images.igdb.com/igdb/image/upload/t_thumb_2x/\(imageId).jpg")
        else {
            return nil
        }
        return imageUrl
    }
}
