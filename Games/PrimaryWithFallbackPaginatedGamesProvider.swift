//
//  Created by Peter Combee on 19/11/2024.
//

struct PrimaryWithFallbackPaginatedGamesProvider: PaginatedGamesProvider {
    
    private let primaryProvider: PaginatedGamesProvider
    private let fallbackProvider: PaginatedGamesProvider
    
    init(
        primaryProvider: PaginatedGamesProvider,
        fallbackProvider: PaginatedGamesProvider
    ) {
        self.primaryProvider = primaryProvider
        self.fallbackProvider = fallbackProvider
    }
    
    func getGames() async throws -> PaginatedGames {
        do { return try await primaryProvider.getGames() }
        catch { return try await fallbackProvider.getGames() }
    }
}
