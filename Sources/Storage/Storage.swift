import Core
import Foundation

public class Storage {
    public enum Error: Swift.Error {
        case missingNetworkDriver
    }
    
    static var networkDriver: NetworkDriver?
    
    @discardableResult
    public static func upload(entity: FileEntity) throws -> String {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        return try networkDriver.upload(entity: entity)
    }
    
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
    
    public static func get(path: String) throws -> Data {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        return try networkDriver.get(path: path)
    }
    
    public static func delete(path: String) throws {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        try networkDriver.delete(path: path)
    }
}
