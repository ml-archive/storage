import XCTest
@testable import Storage

class UploadEntityTests: XCTestCase {
    static var allTests = [
        ("testUploadEntityInit", testUploadEntityInit),
        ("testUploadEntityInitNil", testUploadEntityInitNil),
        ("testUploadEntityValidate", testUploadEntityValidate),
        ("testUploadEntityValidateFailed", testUploadEntityValidateFailed),
        ("testUploadEntityGetFilePath", testUploadEntityGetFilePath),
        ("testUploadEntityGetFilePathFailed", testUploadEntityGetFilePathFailed)
    ]
    
    func testUploadEntityInit() {
        expectNoThrow() {
            let entity = try UploadEntity(
                bytes: "dEadBeef",
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
    }
    
    func testUploadEntityInitNil() {
        expectNoThrow() {
            let entity = try UploadEntity(bytes: "dEadBeef")
            
            XCTAssertNil(entity.fileName)
            XCTAssertNil(entity.fileExtension)
            XCTAssertNil(entity.folder)
        }
    }
    
    func testUploadEntityValidate() {
        expectNoThrow() {
            let entity = try UploadEntity(
                bytes: "dEadBeef",
                fileName: "test_image",
                fileExtension: "png",
                folder: "images"
            )
            
            try entity.verify()
        }
    }
    
    func testUploadEntityValidateFailed() {
        let entity = try! UploadEntity(
            bytes: "dEadBeef",
            fileName: "test_image",
            folder: "images"
        )
        
        expect(toThrow: UploadEntity.Error.missingFileExtension, from: entity.verify)
        
        let entity2 = try! UploadEntity(
            bytes: "dEadBeef",
            fileExtension: "png",
            folder: "images"
        )
        expect(toThrow: UploadEntity.Error.missingFilename, from: entity2.verify)
    }
    
    func testUploadEntityGetFilePath() {
        let entity = try! UploadEntity(
            bytes: "dEadBeef",
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        expect(entity.getFilePath, toReturn: "images/test_image.png")
    }
    
    func testUploadEntityGetFilePathFailed() {
        let entity = try! UploadEntity(
            bytes: "dEadBeef",
            fileExtension: "jpg",
            folder: "images"
        )
        
        expect(toThrow: UploadEntity.Error.missingFilename, from: entity.getFilePath)
        
        let entity2 = try! UploadEntity(
            bytes: "dEadBeef",
            fileName: "profileImage",
            folder: "images"
        )
        
        expect(toThrow: UploadEntity.Error.missingFileExtension, from: entity2.getFilePath)
    }
}
