//
//  Created by Peter Combee on 11/11/2024.
//

import SwiftUI

let session = URLSession(configuration: .ephemeral)
let client = UrlSessionHttpClient(session: session)
let authenticatedClient = BearerAuthenticatedHttpClient(
    httpClient: client,
    clientId: clientId,
    bearerToken: bearerToken
)

private let cache: GamesCache = {
    guard let storeUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("CachedGames") else {
        assertionFailure("Failed to find caches directory required for the CodableGamesStore.")
        fatalError()
    }
    return CodableGamesStore(storeUrl: storeUrl)
}()

private let remoteGamesProvider = IgdbRemoteGamesProvider(client: authenticatedClient)

private let assembler = PaginatedGamesProviderAssembler(
    cache: cache,
    remoteGamesProvider: remoteGamesProvider
)

@main
struct GamesApp: App {

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                makeGameListView(
                    loadGames: assembler.makeLocalWithCachingRemotePaginatedGamesProvider(),
                    reloadGames: assembler.makeCachingRemotePaginatedGamesProvider()
                )
                .navigationTitle("Games")
                .navigationDestination(
                    for: Game.self,
                    destination: { game in
                        makeGameDetailView(game: game)
                            .navigationTitle(game.name)
                    }
                )
            }
        }
    }
    
    func makeGameListView(
        loadGames: @escaping () async throws -> PaginatedGames,
        reloadGames: @escaping () async throws -> PaginatedGames
    ) -> some View {
        PaginatedGamesView(
            viewModel: PaginatedGameListViewModel(
                loadGames: loadGames,
                reloadGames: reloadGames
            ),
            makeGameView: makeGameView
        )
    }
    
    private func makeGameView(game: Game) -> some View {
        NavigationLink(value: game) {
            GameListItemView(
                imageUrl: imageUrl(for: game.imageId),
                name: game.name
            )
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

    func makeGameDetailView(game: Game) -> some View {
        Text(game.name)
    }
}
