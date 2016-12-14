import XCTest
@testable import Storage

class PathBuilderTests: XCTestCase {
    static var allTests = [
        ("testConfigurableBuilderInit", testConfigurableBuilderInit),
        ("testConfigurableBuilder", testConfigurableBuilder)
    ]
    
    func testConfigurableBuilderInit() {
    }
    
    func testConfigurableBuilder() {
        let template = "$folder/$mimeFolder/$fileName.$fileExtension"
        let entity = try! UploadEntity(
            bytes: "",
            fileName: "profileImage",
            fileExtension: "png",
            folder: "app",
            mime: "image/png"
        )
        let builder = ConfigurablePathBuilder(template: template)
        let path = builder.build(entity: entity)
        XCTAssertEqual(path, "app/images/original/profileImage.png")
    }
}
