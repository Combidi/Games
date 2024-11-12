//
//  Created by Peter Combee on 12/11/2024.
//

import Foundation

protocol HttpClient {
    func perform(_ request: URLRequest) async throws -> Data
}
