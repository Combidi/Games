//
//  Created by Peter Combee on 24/11/2024.
//

import SwiftUI

struct GameDetailsView: View {
    
    private let name: String
    private let rating: Double?
    private let description: String?
    private let imageUrl: URL?
    
    init(
        name: String,
        rating: Double?,
        description: String?,
        imageUrl: URL?
    ) {
        self.name = name
        self.rating = rating
        self.description = description
        self.imageUrl = imageUrl
    }
    
    var body: some View {
        List {
            imageUrl.map {
                AsyncImage(
                    url: $0,
                    content: { image in
                        image
                            .cover

                    },
                    placeholder: {
                        Image(systemName: "photo.badge.exclamationmark")
                            .cover
                    }
                )
            }
            Text("Title: \(name)")
            rating.map {
                Text("Rating: \($0)")
            }
            description.map {
                Text("Description: \($0)")
            }
        }
    }
}

private extension Image {
    var cover: some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(5)
    }
}
