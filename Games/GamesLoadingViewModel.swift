//
//  Created by Peter Combee on 15/11/2024.
//

import Foundation

@MainActor
final class GamesLoadingViewModel: ObservableObject {
    
    enum LoadingState: Equatable {
        case loading
        case error
        case loaded([Game])
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
    
    @Published private(set) var state: LoadingState = .loading
    
    func load() async {
        if state != .loading { state = .loading }
        do { state = .loaded(try await loadGames()) }
        catch { state = .error }
    }
    
    func reload() async {
        do { state = .loaded(try await reloadGames()) }
        catch { state = .error }
     }
}
