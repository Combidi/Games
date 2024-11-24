//
//  Created by Peter Combee on 17/11/2024.
//

import SwiftUI

struct LoadMoreView: View {
    
    private enum LoadMoreState {
        case loading
        case error
    }

    private let loadMore: () async throws -> Void

    init(loadMore: @escaping () async throws -> Void) {
        self.loadMore = loadMore
    }
        
    @State private var state: LoadMoreState = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                HStack {
                    ProgressView("Loading more...")
                }
            case .error:
                Button(action: reload) {
                    Text("Retry")
                }
            }
        }
        .performTaskOnFirstAppearance {
            await load()
        }
    }
    
    private func load() async {
        do { try await loadMore() }
        catch { state = .error }
    }
    
    private func reload() {
        state = .loading
        Task { await load() }
    }
}

#Preview {
    LoadMoreView { try? await Task.sleep(nanoseconds: UInt64.max) }
}

#Preview {
    LoadMoreView { throw NSError(domain: "any", code: 0) }
}
