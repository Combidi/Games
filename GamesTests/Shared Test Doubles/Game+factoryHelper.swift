//
//  Created by Peter Combee on 23/11/2024.
//

@testable import Games

func makeGame(id: Int) -> Game {
    Game(id: id, name: "Game \(id)", imageId: nil)
}
