import XCTest
@testable import Storage

class PathBuilderTests: XCTestCase {
    static var allTests = [
        ("testTemplate", testTemplate),
        ("testConfigurableBuilderInit", testConfigurableBuilderInit),
        ("testConfigurableBuilder", testConfigurableBuilder)
    ]
    
    func testTemplate() {
        let template = try! Template.compile("test/$folder/$file")
        
        let entity = try! FileEntity(
            fileName: "profileImage",
            fileExtension: "png",
            folder: "app",
            mime: "image/png"
        )
        
        let path = try! template.renderPath(entity: entity)
        XCTAssertEqual(path, "test/app/profileImage.png")
    }
    
    func testConfigurableBuilderInit() {
        let template = "$folder/$mimeFolder/$fileName.$fileExtension"
        
        expectNoThrow() {
            let _ = try ConfigurablePathBuilder(template: template)
        }
    }
    
    func testConfigurableBuilder() {
        let template = "$folder/$fileName.$fileExtension"
        let entity = try! FileEntity(
            fileName: "profileImage",
            fileExtension: "png",
            folder: "app",
            mime: "image/png"
        )
        let builder = try! ConfigurablePathBuilder(template: template)
        let path = try! builder.build(entity: entity)
        XCTAssertEqual(path, "app/profileImage.png")
    }
}
