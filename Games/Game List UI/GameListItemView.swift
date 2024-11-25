//
//  Created by Peter Combee on 13/11/2024.
//

import SwiftUI

struct GameListItemView: View {
    
    private let imageUrl: URL?
    private let name: String
        
    init(imageUrl: URL?, name: String) {
        self.imageUrl = imageUrl
        self.name = name
    }
    
    var body: some View {
        HStack {
            if let imageUrl {
                image(for: imageUrl)
            } else {
                placeholderImage
            }
            Text(name)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func image(for url: URL) -> some View {
        AsyncImage(
            url: imageUrl,
            content: { image in
                image.thumbnail

            },
            placeholder: {
                placeholderImage
            }
        )
    }
    
    private var placeholderImage: some View {
        Image(systemName: "photo.badge.exclamationmark")
            .thumbnail
    }
}

private extension Image {
    var thumbnail: some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 100)
            .cornerRadius(5)
    }
}

#Preview {
    
    func imageUrl(imageId: String) -> URL {
        URL(string: "https://images.igdb.com/igdb/image/upload/t_cover_small_2x/\(imageId).jpg")!
    }
    
    return List {
        GameListItemView(
            imageUrl: imageUrl(imageId: "co5qi9"),
            name: "Maji Kyun! Renaissance"
        )
        GameListItemView(
            imageUrl: nil,
            name: "Maji Kyun! Renaissance"
        )
        GameListItemView(
            imageUrl: URL(string: "any.url.com")!,
            name: "Commando"
        )
        GameListItemView(
            imageUrl: imageUrl(imageId: "co2k3z"),
            name: "Commando"
        )
    }
    .listStyle(.plain)
}
