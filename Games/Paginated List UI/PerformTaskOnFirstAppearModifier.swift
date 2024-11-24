
//
//  Created by Peter Combee on 24/11/2024.
//

import SwiftUI

private struct PerformTaskOnFirstAppearModifier: ViewModifier {

    private let action: () async -> Void
    
    public init(_ action: @escaping () async -> Void) {
        self.action = action
    }

    @State private var hasAppeared = false
    
    public func body(content: Content) -> some View {
        content
            .task {
                guard !hasAppeared else { return }
                hasAppeared = true
                await action()
            }
    }
}

extension View {
    func performTaskOnFirstAppearance(_ action: @escaping () async -> Void) -> some View {
        return modifier(PerformTaskOnFirstAppearModifier(action))
    }
}
