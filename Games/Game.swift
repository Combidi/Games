//
//  Created by Peter Combee on 12/11/2024.
//

struct Game: Hashable, Identifiable {
    let id: Int
    let name: String
    let imageId: String?
    let rating: Double?
    let description: String?
}
