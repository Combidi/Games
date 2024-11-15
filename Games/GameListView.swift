//
//  Created by Peter Combee on 15/11/2024.
//

import SwiftUI

struct GameListView: View {
    
    let games: [Game]
    
    var body: some View {
        List(games, id: \.id) { game in
            GameListItemView(
                imageUrl: imageUrl(for: game.imageId),
                name: game.name
            )
            .listRowSeparator(.hidden)
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

#Preview {
    GameListView(games: [
        Game(id: 0, name: "Maji Kyun! Renaissance", imageId: "co5qi9"),
        Game(id: 1, name: "Commando", imageId: nil),
        Game(id: 2, name: "Commando", imageId: "co2k3z")
    ])
}
