//
//  Created by Peter Combee on 17/11/2024.
//

struct Paginated<Resource> {
    let resource: Resource
    let loadMore: (() async throws -> Self)?
}
