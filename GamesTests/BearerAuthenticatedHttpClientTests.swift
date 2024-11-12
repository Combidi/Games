//
//  Created by Peter Combee on 12/11/2024.
//

import XCTest
@testable import Games

final class BearerAuthenticatedHttpClientTests: XCTestCase {

    func test_perform_performsAuthenticatedRequestOnHttpClient() async throws {
        let httpClient = HttpClientSpy()
        let sut = BearerAuthenticatedHttpClient(
            httpClient: httpClient,
            clientId: "any-client-id",
            bearerToken: "any-bearer-token"
        )
        
        let request = URLRequest(url: URL(string: "https://example.com")!)
        
        _ = try? await sut.perform(request)
        
        let performedRequest = try XCTUnwrap(httpClient.capturedRequest)
        
        XCTAssertEqual(performedRequest.value(forHTTPHeaderField: "Client-ID"), "any-client-id")
        XCTAssertEqual(performedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer any-bearer-token")
    }
}
