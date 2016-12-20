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
            folder: "images",
            mime: "image/jpg"
        )
        
        expectNoThrow() {
            let builder = try ConfigurablePathBuilder(template: "$folder/$file")
            let path = try builder.build(entity: entity)
            XCTAssertEqual(path, "images/smile.jpg")
        }
    }
    
    func testConfigurablePathBuilderFailed() {
    }
}
