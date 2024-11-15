//
//  Created by Peter Combee on 15/11/2024.
//

import SwiftUI

struct GamesLoadingView: View {
    
    enum LoadingState {
        case loading
        case loaded([Game])
        case error
    }
    
    @State var state: LoadingState = .loading
    
    var body: some View {
        switch state {
        case .loading:
            Text("Loading...")
            
        case .loaded(let games):
            GameListView(games: games)
            
        case .error:
            Text("Oeps, something went wrong.")

        }
    }
}

#Preview("Loading state") {
    GamesLoadingView(state: .loading)
}

#Preview("Error state") {
    GamesLoadingView(state: .error)
}

#Preview("Loaded state") {
    GamesLoadingView(state: .loaded([
        Game(id: 0, name: "Maji Kyun! Renaissance", imageId: "co5qi9"),
        Game(id: 1, name: "Commando", imageId: nil),
        Game(id: 2, name: "Commando", imageId: "co2k3z")
    ]))
}
