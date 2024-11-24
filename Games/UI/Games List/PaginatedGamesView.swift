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
    
    private func listView(for games: PresentableGames) -> some View {
        List {
            ForEach(games.games, id: \.id) { game in
                makeGameView(game)
                    .listRowSeparator(.hidden)
            }
            loadMoreView(loadMore: games.loadMore)
        }
        .refreshable(action: { await viewModel.reload() })
    }
    
    private func loadMoreView(loadMore: (() async throws -> Void)?) -> some View {
        loadMore.map { loadMore in
            HStack {
                Spacer()
                LoadMoreView(loadMore: loadMore)
                Spacer()
            }
        }
    }
}

public struct PerformTaskOnFirstAppearModifier: ViewModifier {

    private let action: () async -> Void
    @State private var hasAppeared = false
    
    public init(_ action: @escaping () async -> Void) {
        self.action = action
    }
    
    public func body(content: Content) -> some View {
        content
            .task {
                guard !hasAppeared else { return }
                hasAppeared = true
                await action()
            }
    }
}

extension View {
    func performTaskOnFirstAppearance(_ action: @escaping () async -> Void) -> some View {
        return modifier(PerformTaskOnFirstAppearModifier(action))
    }
}
