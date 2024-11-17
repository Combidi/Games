//
//  Created by Peter Combee on 17/11/2024.
//

import SwiftUI

struct LoadMoreView: View {
    
    let loadMore: () async throws -> Void
    
    private enum LoadMoreState {
        case loading
        case error
    }
    
    @State private var state: LoadMoreState = .loading
    
    var body: some View {
        switch state {
        case .loading:
            Text("Loading more...")
                .onAppear { load() }
        case .error:
            Button(action: load) {
                Text("Retry")
            }
        }
    }
    
    private func load() {
        Task {
            do { try await loadMore() }
            catch {
                state = .error
            }
        }
    }
}
