import XCTest
@testable import Storage

class PathBuilderTests: XCTestCase {
    static var allTests = [
        ("testConfigurablePathBuilder", testConfigurablePathBuilder),
        ("testConfigurablePathBuilderFailed", testConfigurablePathBuilderFailed)
    ]
    
    func testConfigurablePathBuilder() {
        let entity = FileEntity(
            fileName: "smile",
            fileExtension: "jpg",
            mime: "image/jpg"
        )
        
        expectNoThrow() {
            let builder = try ConfigurablePathBuilder(template: "/myapp/$mimeFolder/$file")
            let path = try builder.build(entity: entity)
            XCTAssertEqual(path, "/myapp/images/original/smile.jpg")
        }
    }
    
    func testConfigurablePathBuilderFailed() {
    }
}
