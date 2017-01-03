import XCTest
@testable import Storage

class FileEntityTests: XCTestCase {
    static var allTests = [
        ("testFileEntityInit", testFileEntityInit),
        ("testFileEntityInitNil", testFileEntityInitNil),
        ("testFileEntityValidate", testFileEntityValidate),
        ("testFileEntityValidateFailed", testFileEntityValidateFailed),
        ("testFileEntityGetFilePath", testFileEntityGetFilePath),
        ("testFileEntityGetFilePathFailed", testFileEntityGetFilePathFailed),
        ("testFileEntityWithExtensionInName", testFileEntityWithExtensionInName)
    ]
    
    func testFileEntityInit() {
        let entity = FileEntity(
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        XCTAssertNotNil(entity.fileName)
        XCTAssertNotNil(entity.folder)
        XCTAssertNotNil(entity.fileExtension)
        
        XCTAssertEqual(entity.fileName, "test_image")
        XCTAssertEqual(entity.fileExtension, "png")
        XCTAssertEqual(entity.folder, "images")
    }
    
    func testFileEntityInitNil() {
        let entity = FileEntity()
        
        XCTAssertNil(entity.bytes)
        XCTAssertNil(entity.fileName)
        XCTAssertNil(entity.fileExtension)
        XCTAssertNil(entity.folder)
    }
    
    func testFileEntityValidate() {
        let entity = FileEntity(
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        expectNoThrow(entity.verify)
    }
    
    func testFileEntityValidateFailed() {
        let entity = FileEntity(
            fileName: "test_image",
            folder: "images"
        )
        
        expect(toThrow: FileEntity.Error.missingFileExtension, from: entity.verify)
        
        let entity2 = FileEntity(
            fileExtension: "png",
            folder: "images"
        )
        expect(toThrow: FileEntity.Error.missingFilename, from: entity2.verify)
    }
    
    func testFileEntityGetFilePath() {
        let entity = FileEntity(
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        expect(entity.getFilePath, toReturn: "images/test_image.png")
    }
    
    func testFileEntityGetFilePathFailed() {
        let entity = FileEntity(
            fileExtension: "jpg",
            folder: "images"
        )
        
        expect(toThrow: FileEntity.Error.malformedFileName, from: entity.getFilePath)
        
        let entity2 = FileEntity(
            fileName: "profileImage",
            folder: "images"
        )
        
        expect(toThrow: FileEntity.Error.malformedFileName, from: entity2.getFilePath)
    }
    
    func testFileEntityWithExtensionInName() {
        let entity = FileEntity(
            fileName: "test.png"
        )
        
        XCTAssertEqual(entity.fileName, "test")
        XCTAssertEqual(entity.fileExtension, "png")
        XCTAssertEqual(entity.fullFileName, "test.png")
    }
}
