//
//  Created by Peter Combee on 24/11/2024.
//

import SwiftUI

struct GameDetailsView: View {
    
    private let game: Game
    
    init(game: Game) {
        self.game = game
    }
    
    var body: some View {
        List {
            imageUrl(for: game.imageId).map {
                AsyncImage(url: $0)
            }
            Text("Title: \(game.name)")
            game.rating.map {
                Text("Rating: \($0)")
            }
            game.description.map {
                Text("Description: \($0)")
            }
        }
    }
    
    private func imageUrl(for imageId: String?) -> URL? {
        guard
            let imageId = imageId,
            let imageUrl = URL(string: "https://images.igdb.com/igdb/image/upload/t_thumb_2x/\(imageId).jpg")
        else {
            return nil
        }
        return imageUrl
    }
}
