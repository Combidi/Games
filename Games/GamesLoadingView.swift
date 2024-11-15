//
//  Created by Peter Combee on 15/11/2024.
//

import SwiftUI

struct GamesLoadingView<GameView: View>: View {
            
    @ObservedObject private var viewModel: GamesLoadingViewModel
    private let makeGameView: (Game) -> GameView

    init(
        viewModel: GamesLoadingViewModel,
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
                
            case .loaded(let games):
                listView(for: games)

            case .error:
                Text("Oeps, something went wrong.")
                
            }
        }
        .task { await viewModel.load() }
    }
    
    private func listView(for games: [Game]) -> some View {
        List(games, id: \.id) { game in
            makeGameView(game)
                .listRowSeparator(.hidden)
        }
        .refreshable(action: { await viewModel.reload() })
    }    
}
