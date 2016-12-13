import XCTest
@testable import Storage

class storageTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(storage().text, "Hello, World!")
    }


    static var allTests : [(String, (storageTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
