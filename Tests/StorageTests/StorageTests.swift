import XCTest
@testable import Storage

class StorageTests: XCTestCase {
    static var allTests = [
        ("testSettingsInit", testSettingsInit),
        ("testSettingsInitNil", testSettingsInitNil),
        ("testSettingsValidate", testSettingsValidate),
        ("testSettingsValidateFailed", testSettingsValidateFailed),
        ("testSettingsGetFilePath", testSettingsGetFilePath),
        ("testSettingsGetFilePathFailed", testSettingsGetFilePathFailed)
    ]

    func testSettingsInit() {
        let settings = Settings(
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        XCTAssertNotNil(settings.fileName)
        XCTAssertNotNil(settings.folder)
        XCTAssertNotNil(settings.fileExtension)
        
        XCTAssertEqual(settings.fileName, "test_image")
        XCTAssertEqual(settings.fileExtension, "png")
        XCTAssertEqual(settings.folder, "images")
    }
    
    func testSettingsInitNil() {
        let settings = Settings()
        
        XCTAssertNil(settings.fileName)
        XCTAssertNil(settings.fileExtension)
        XCTAssertNil(settings.folder)
    }
    
    func testSettingsValidate() {
        let settings = Settings(
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        do {
            try settings.verify()
        } catch {
            XCTFail("should not have thrown")
        }
    }
    
    func testSettingsValidateFailed() {
        let settings = Settings(
            fileName: "test_image",
            folder: "images"
        )
        
        do {
            try settings.verify()
            XCTFail("should have thrown")
        } catch {
            guard let error = error as? Settings.Error else {
                XCTFail("should have thrown `Settings.Error` type")
                return
            }
            
            XCTAssertEqual(error, Settings.Error.missingFileExtension)
        }
    }
    
    func testSettingsGetFilePath() {
        let settings = Settings(
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        var path = ""
        do {
            path = try settings.getFilePath()
        } catch {
            XCTFail("should not have thrown: \(error)")
        }
        
        XCTAssertEqual(path, "images/test_image.png")
    }
    
    func testSettingsGetFilePathFailed() {
        let settings = Settings(
            fileExtension: "jpg",
            folder: "images"
        )
        
        do {
            let _ = try settings.getFilePath()
            XCTFail("getFilePath should have thrown")
        } catch {
            guard let error = error as? Settings.Error else {
                XCTFail("should have thrown `Settings.Error` type")
                return
            }
            
            XCTAssertEqual(error, Settings.Error.missingFilename)
        }
    }
    
}
