//
//  Created by Peter Combee on 12/11/2024.
//

import Foundation

struct UrlSessionHttpClient: HttpClient {
    
    private struct NonHttpResponseError: Error {}
    
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw NonHttpResponseError()
        }
        return (data, response)
    }
}
