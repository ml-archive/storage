import XCTest
@testable import StorageTests

XCTMain([
    testCase(StorageTests.allTests), 
    testCase(FileEntityTests.allTests),
    testCase(TemplateTests.allTests),
    testCase(PathBuilderTests.allTests)
])
