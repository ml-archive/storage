import XCTest
@testable import StorageTests

XCTMain([
    testCase(FileEntityTests.allTests),
    testCase(TemplateTests.allTests),
    testCase(PathBuilderTests.allTests),
    testCase(AWSSignerTestSuite)
])
