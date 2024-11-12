//
//  Created by Peter Combee on 12/11/2024.
//

import XCTest
@testable import Games

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

// MARK: - Helpers

private final class HttpClientSpy: HttpClient {
    
    var stub: Result<Data, Error> = .success(Data())
    
    private(set) var capturedRequest: URLRequest?
    
    func perform(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        capturedRequest = request
        return (try stub.get(), HTTPURLResponse())
    }
}
