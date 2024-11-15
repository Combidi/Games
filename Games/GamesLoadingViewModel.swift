//
//  Created by Peter Combee on 15/11/2024.
//

import Foundation

final class GamesLoadingViewModel {
    
    enum LoadingState: Equatable {
        case loading
        case error
        case loaded([Game])
    }
    
    private let loadGames: () throws -> [Game]
    private let reloadGames: () throws -> [Game]
    init(
        loadGames: @escaping () throws -> [Game],
        reloadGames: @escaping () throws -> [Game]
    ) {
        self.loadGames = loadGames
        self.reloadGames = reloadGames
    }
    
    @Published private(set) var state: LoadingState = .loading
    
    func load() {
        if state != .loading { state = .loading }
        do { state = .loaded(try loadGames()) }
        catch { state = .error }
    }
    
    func reload() {
        do { state = .loaded(try reloadGames()) }
        catch { state = .error }
     }
}
