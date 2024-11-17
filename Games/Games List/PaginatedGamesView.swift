//
//  Created by Peter Combee on 17/11/2024.
//

import SwiftUI

struct PaginatedGamesView<GameView: View>: View {
            
    @ObservedObject private var viewModel: PaginatedGameListViewModel
    private let makeGameView: (Game) -> GameView

    init(
        viewModel: PaginatedGameListViewModel,
        makeGameView: @escaping (Game) -> GameView
    ) {
        self.viewModel = viewModel
        self.makeGameView = makeGameView
    }
        
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                Text("Loading...")
                
            case .loaded(let presentable):
                listView(for: presentable)

            case .error:
                Text("Oeps, something went wrong.")
                
            }
        }
        .task { await viewModel.load() }
    }
    
    private func listView(for games: PresentableGames) -> some View {
        List {
            ForEach(games.games, id: \.id) { game in
                makeGameView(game)
                    .listRowSeparator(.hidden)
            }
            games.loadMore.map(LoadMoreView.init)
        }
        .refreshable(action: { await viewModel.reload() })
    }
}
