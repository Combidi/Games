//
//  Created by Peter Combee on 20/11/2024.
//

import XCTest

func assertThrowsAsyncError<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        let result = try await expression()
        XCTFail("Expected asynchronous call to throw, got \(result) instead", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
