import XCTest
@testable import StorageTests

XCTMain([
     testCase(UploadEntityTests.allTests),
     testCase(PathBuilderTests.allTests)
])
