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
        
        expectNoThrow(settings.verify)
    }
    
    func testSettingsValidateFailed() {
        let settings = Settings(
            fileName: "test_image",
            folder: "images"
        )
        
        expect(toThrow: Settings.Error.missingFileExtension, from: settings.getFilePath)
    }
    
    func testSettingsGetFilePath() {
        let settings = Settings(
            fileName: "test_image",
            fileExtension: "png",
            folder: "images"
        )
        
        expect(settings.getFilePath, toReturn: "images/test_image.png")
    }
    
    func testSettingsGetFilePathFailed() {
        let settings = Settings(
            fileExtension: "jpg",
            folder: "images"
        )
        
        expect(toThrow: Settings.Error.missingFilename, from: settings.getFilePath)
    }
    
}
