//
//  Created by Peter Combee on 17/11/2024.
//

import Foundation

@MainActor
final class PaginatedListViewModel<ListItem: Equatable & Identifiable>: ObservableObject {
    
    typealias Page = Paginated<[ListItem]>
    typealias Presentable = PresentableListItems<ListItem>
    
    enum LoadingState: Equatable {
        case loading
        case error
        case loaded(PresentableListItems<ListItem>)
    }
    
    private let load: () async throws -> Page
    private let reload: () async throws -> Page
    
    init(
        load: @escaping () async throws -> Page,
        reload: @escaping () async throws -> Page
    ) {
        self.load = load
        self.reload = reload
    }
    
    @Published private(set) var state: LoadingState = .loading
    
    func load() async {
        if state != .loading { state = .loading }
        await load(using: load)
    }
    
    func reload() async {
        await load(using: reload)
    }
    
    private func load(using loadAction: () async throws -> Page) async {
        do {
            let page = try await loadAction()
            let presentable = Presentable(
                items: page.resource,
                loadMore: loadNextPage(current: page)
            )
            state = .loaded(presentable)
        }
        catch {
            state = .error
        }
    }
    
    private func loadNextPage(current: Page) -> (() async throws -> Void)? {
        guard let loadMore = current.loadMore else { return nil }
        return { [self] in
            let nextPage = try await loadMore()
            let presentable = Presentable(
                items: nextPage.resource,
                loadMore: loadNextPage(current: nextPage)
            )
            state = .loaded(presentable)
        }
    }
}
