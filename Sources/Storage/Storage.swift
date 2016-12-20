import Core
import Foundation

public class Storage {
    public enum Error: Swift.Error {
        case missingNetworkDriver
    }
    
    static var networkDriver: NetworkDriver?
    
    /**
        Uploads the given `FileEntity`.
     
        - Parameters:
            - entity: The `FileEntity` to be uploaded.
     
        - Returns: The path the file was uploaded to.
     */
    @discardableResult
    public static func upload(entity: FileEntity) throws -> String {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        return try networkDriver.upload(entity: entity)
    }
    
    /**
     Uploads bytes to a storage server.
     
     - Parameters:
        - bytes: The raw bytes of the file.
        - fileName: The name of the file.
        - fileExtension: The extension of the file.
        - mime: The mime type of the file.
        - folder: The folder the file came from.
     
     - Returns: The path the file was uploaded to.
     */
    @discardableResult
    public static func upload(
        bytes: Bytes,
        fileName: String? = nil,
        fileExtension: String? = nil,
        mime: String? = nil,
        folder: String? = nil
    ) throws -> String {
        let entity = FileEntity(
            bytes: bytes,
            fileName: fileName,
            fileExtension: fileExtension,
            folder: folder,
            mime: mime
        )
        
        return try upload(entity: entity)
    }
    
    /**
     Uploads a base64 encoded URI to a storage server.
     
     - Parameters:
        - base64: The raw, base64 encoded, bytes of the file in `String` representation.
        - fileName: The name of the file.
        - fileExtension: The extension of the file.
        - mime: The mime type of the file.
        - folder: The folder the file came from.
     
     - Returns: The path the file was uploaded to.
     */
    @discardableResult
    public static func upload(
        base64: String,
        fileName: String? = nil,
        fileExtension: String? = nil,
        mime: String? = nil,
        folder: String? = nil
    ) throws -> String {
        return try upload(
            bytes: base64.base64Decoded,
            fileName: fileName,
            fileExtension: fileExtension,
            mime: mime,
            folder: folder
        )
    }
    
    /**
        Downloads the file at `path`.
     
        - Parameters:
            - path: The path of the file to be downloaded.
     
        - Returns: The downloaded file as `NSData`.
     */
    public static func get(path: String) throws -> Data {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        return try networkDriver.get(path: path)
    }
    
    /**
        Deletes the file at `path`.
     
        - Parameters:
            - path: The path of the file to be deleted.
     */
    public static func delete(path: String) throws {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        try networkDriver.delete(path: path)
    }
}
