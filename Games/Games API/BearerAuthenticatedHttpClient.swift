//
//  Created by Peter Combee on 12/11/2024.
//

import Foundation

struct BearerAuthenticatedHttpClient: HttpClient {
    
    private let httpClient: HttpClient
    private let clientId: String
    private let bearerToken: String
    
    init(httpClient: HttpClient, clientId: String, bearerToken: String) {
        self.httpClient = httpClient
        self.clientId = clientId
        self.bearerToken = bearerToken
    }
    
    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var request = request
        request.setValue(clientId, forHTTPHeaderField: "Client-ID")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return try await httpClient.perform(request)
    }
}
