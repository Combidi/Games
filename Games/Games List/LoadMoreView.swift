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
            HStack {
                ProgressView("Loading more...")
            }
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

#Preview {
    LoadMoreView { try? await Task.sleep(nanoseconds: UInt64.max) }
}

#Preview {
    LoadMoreView { throw NSError(domain: "any", code: 0) }
}
