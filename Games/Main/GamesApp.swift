//
//  Created by Peter Combee on 11/11/2024.
//

import SwiftUI

private let session = URLSession(configuration: .ephemeral)
private let client = UrlSessionHttpClient(session: session)
private let authenticatedClient = BearerAuthenticatedHttpClient(
    httpClient: client,
    clientId: clientId,
    bearerToken: bearerToken
)
private let remoteGamesProvider = IgdbRemoteGamesProvider(client: authenticatedClient)
private let cache: GamesCache = {
    guard let storeUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("CachedGames") else {
        assertionFailure("Failed to find caches directory required for the CodableGamesStore.")
        return NullGameStore()
    }
    return CodableGamesStore(storeUrl: storeUrl)
}()
private let assembler = PaginatedGamesProviderAssembler(
    cache: cache,
    remoteGamesProvider: remoteGamesProvider
)

@main
struct GamesApp: App {

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                gameListView
            }
        }
    }
    
    private var gameListView: some View {
        PaginatedGamesView(
            viewModel: PaginatedGameListViewModel(
                loadGames: assembler.makeLocalWithCachingRemotePaginatedGamesProvider(),
                reloadGames: assembler.makeCachingRemotePaginatedGamesProvider()
            ),
            makeGameView: makeGameListItemView
        )
        .navigationTitle("Games")
        .navigationDestination(
            for: Game.self,
            destination: makeGameDetailView
        )
    }
    
    private func makeGameListItemView(game: Game) -> some View {
        NavigationLink(value: game) {
            GameListItemView(
                imageUrl: imageUrl(for: game.imageId),
                name: game.name
            )
        }
    }
    
    private func makeGameDetailView(game: Game) -> some View {
        GameDetailsView(
            name: game.name,
            rating: game.rating,
            description: game.description,
            imageUrl: imageUrl(for: game.imageId)
        )
        .navigationTitle(game.name)
    }

    private func imageUrl(for imageId: String?) -> URL? {
        guard
            let imageId = imageId,
            let imageUrl = URL(string: "https://images.igdb.com/igdb/image/upload/t_cover_small_2x/\(imageId).jpg")
        else {
            return nil
        }
        return imageUrl
    }
}
