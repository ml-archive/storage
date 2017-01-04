import XCTest
@testable import Storage

class PathBuilderTests: XCTestCase {
    static var allTests = [
        ("testConfigurableNodesPathTemplate", testConfigurableNodesPathTemplate),
        ("testConfigurableAllAliases", testConfigurableAllAliases),
        ("testConfigurableAllAliasesFailed", testConfigurableAllAliasesFailed)
    ]
    
    func testConfigurableNodesPathTemplate() {
        let entity = FileEntity(
            fileName: "smile",
            fileExtension: "jpg",
            mime: "image/jpg"
        )
        
        expectNoThrow() {
            let builder = try ConfigurablePathBuilder(template: "/myapp/#mimeFolder/#file")
            let path = try builder.build(entity: entity)
            XCTAssertEqual(path, "/myapp/images/original/smile.jpg")
        }
    }
    
    func testConfigurableAllAliases() {
        let entity = FileEntity(
            fileName: "test.png",
            folder: "myfolder",
            mime: "image/png"
        )
        
        let expected: [(Template.Alias, String)] = [
            (.file, "test.png"),
            (.fileName, "test"),
            (.fileExtension, "png"),
            (.folder, "myfolder"),
            (.mime, "image/png"),
            (.mimeFolder, "images/original")
        ]
        
        expectNoThrow() {
            try expected.forEach { (alias, expected) in
                let builder = try ConfigurablePathBuilder(template: alias.rawValue)
                let path = try builder.build(entity: entity)
                XCTAssertEqual(path, expected)
            }
        }
    }
    
    func testConfigurableAllAliasesFailed() {
        let entity = FileEntity()
        
        let expected: [(Template.Alias, Template.Error)] = [
            (.file,  .malformedFileName),
            (.fileName, .fileNameNotProvided),
            (.fileExtension, .fileExtensionNotProvided),
            (.folder, .folderNotProvided),
            (.mime, .mimeNotProvided),
            (.mimeFolder, .mimeFolderNotProvided)
        ]
        
        expected.forEach { (alias, error) in
            expect(toThrow: error) {
                let builder = try ConfigurablePathBuilder(template: alias.rawValue)
                _ = try builder.build(entity: entity)
            }
        }
    }
}
