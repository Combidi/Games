//
//  Created by Peter Combee on 12/11/2024.
//

import Foundation
@testable import Games

final class HttpClientSpy: HttpClient {
    
    var stub: Result<Data, Error> = .success(Data())
    
    private(set) var capturedRequest: URLRequest?
    
    func perform(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        capturedRequest = request
        return (try stub.get(), HTTPURLResponse())
    }
}
