//
//  Created by Peter Combee on 17/11/2024.
//

import SwiftUI

struct PaginatedList<ListItemView: View, ListItem: Equatable & Identifiable>: View {

    typealias ViewModel = PaginatedListViewModel<ListItem>

    @ObservedObject private var viewModel: ViewModel
    private let makeListItemView: (ListItem) -> ListItemView

    init(
        viewModel: ViewModel,
        makeListItemView: @escaping (ListItem) -> ListItemView
    ) {
        self.viewModel = viewModel
        self.makeListItemView = makeListItemView
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
    
    private func listView(for presentable: ViewModel.Presentable) -> some View {
        List {
            ForEach(presentable.items, id: \.id) { item in
                makeListItemView(item)
                    .listRowSeparator(.hidden)
            }
            loadMoreView(for: presentable)
        }
        .refreshable(action: { await viewModel.reload() })
    }
    
    private func loadMoreView(for presentable: ViewModel.Presentable) -> some View {
        presentable.loadMore.map { loadMore in
            HStack {
                Spacer()
                LoadMoreView(loadMore: loadMore)
                Spacer()
            }
            .id(presentable.items.count)
        }
    }
}
