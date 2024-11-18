//
//  Created by Peter Combee on 17/11/2024.
//

struct PresentableListItems<ListItem: Equatable>: Equatable {
    
    let items: [ListItem]
    let loadMore: (() async throws -> Void)?

    static func == (lhs: Self, rhs: Self) -> Bool {
        rhs.items == lhs.items
    }
}
