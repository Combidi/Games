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
                ProgressView("Loading...")
                
            case .loaded(let presentable):
                listView(for: presentable)

            case .error:
                VStack {
                    Text("Oeps, something went wrong.")
                    Button(action: { Task { await viewModel.load() } }) {
                        Text("Try again")
                    }
                }
            }
        }
        .performTaskOnFirstAppearance { await viewModel.load() }
    }
    
    private func listView(for presentableGames: PresentableGames) -> some View {
        List {
            ForEach(presentableGames.games, id: \.id) { game in
                makeGameView(game)
                    .listRowSeparator(.hidden)
            }
            loadMoreView(for: presentableGames)
        }
        .refreshable(action: { await viewModel.reload() })
    }
    
    private func loadMoreView(for presentableGames: PresentableGames) -> some View {
        presentableGames.loadMore.map { loadMore in
            HStack {
                Spacer()
                LoadMoreView(loadMore: loadMore)
                Spacer()
            }
            .id(presentableGames.games.count)
        }
    }
}
