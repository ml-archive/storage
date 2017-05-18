import Core
import HTTP
import Vapor
import DataURI
import Transport
import Foundation
import FormData

public class Storage {
    public enum Error: Swift.Error {
        case missingNetworkDriver
        case cdnBaseURLNotSet
        case missingFileName
    }
    
    static var networkDriver: NetworkDriver?
    static var cdnBaseURL: String?
    
    public static var cdnPathBuilder: ((String, String) -> String)?
    
    /**
        Uploads the given `FileEntity`.
     
        - Parameters:
            - entity: The `FileEntity` to be uploaded.
     
        - Returns: The path the file was uploaded to.
     */
    @discardableResult
    public static func upload(entity: inout FileEntity) throws -> String {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        return try networkDriver.upload(entity: &entity)
    }
    
    @discardableResult
    public static func upload(
        formData: Field,
        fileName overrideFileName: String? = nil,
        fileExtension: String? = nil,
        folder: String? = nil
    ) throws -> String {
        let fileName = formData.filename
        let bytes = formData.part.body
        
        return try upload(
            bytes: bytes,
            fileName: overrideFileName ?? fileName,
            fileExtension: fileExtension,
            folder: folder
        )
    }
    
    /**
        Downloads the file located at `url` and then uploads it.
     
        - Parameters:
            - url: The location of the file to be downloaded.
            - fileName: The name of the file.
            - fileExtension: The extension of the file.
            - folder: The folder to save the file in.
     
        - Returns: The path the file was uploaded to.
     */
    @discardableResult
    public static func upload(
        url: String,
        fileName: String,
        fileExtension: String? = nil,
        folder: String? = nil
    ) throws -> String {
        let response = try EngineClient.factory.get(url)
        var entity = FileEntity(
            fileName: fileName,
            fileExtension: fileExtension,
            folder: folder
        )
        
        entity.bytes = response.body.bytes
        entity.mime = response.contentType
        
        return try upload(entity: &entity)
    }
    
    /**
        Uploads bytes to a storage server.
     
        - Parameters:
            - bytes: The raw bytes of the file.
            - fileName: The name of the file.
            - fileExtension: The extension of the file.
            - mime: The mime type of the file.
            - folder: The folder to save the file in.
     
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
        var entity = FileEntity(
            bytes: bytes,
            fileName: fileName,
            fileExtension: fileExtension,
            folder: folder,
            mime: mime
        )
        
        return try upload(entity: &entity)
    }
    
    /**
        Uploads a base64 encoded URI to a storage server.
     
        - Parameters:
            - base64: The raw, base64 encoded, bytes of the file in `String` representation.
            - fileName: The name of the file.
            - fileExtension: The extension of the file.
            - mime: The mime type of the file.
            - folder: The folder to save the file in.
     
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
            bytes: base64.makeBytes().base64Decoded,
            fileName: fileName,
            fileExtension: fileExtension,
            mime: mime,
            folder: folder
        )
    }
    
    /**
        Decodes and uploads a data URI.
     
        - Parameters:
            - dataURI: The data URI to be decoded.
            - fileName: The name of the file.
            - fileExtension: The extension of the file.
            - folder: The folder to save the file in.
     
        - Returns: The path the file was uploaded to.
     */
    @discardableResult
    public static func upload(
        dataURI: String,
        fileName: String? = nil,
        fileExtension: String? = nil,
        folder: String? = nil
    ) throws -> String {
        let (bytes, type) = try dataURI.dataURIDecoded()
        return try upload(
            bytes: bytes,
            fileName: fileName,
            fileExtension: fileExtension,
            mime: type,
            folder: folder
        )
    }
    
    /**
        Downloads the file at `path`.
     
        - Parameters:
            - path: The path of the file to be downloaded.
     
        - Returns: The downloaded file as `Bytes`/`[UInt8]`.
     */
    public static func get(path: String) throws -> Bytes {
        guard let networkDriver = networkDriver else {
            throw Error.missingNetworkDriver
        }
        
        return try networkDriver.get(path: path)
    }
    
    /// Appends the asset's path with the base CDN URL.
    public static func getCDNPath(for path: String) throws -> String {
        guard let cdnBaseURL = cdnBaseURL else {
            throw Error.cdnBaseURLNotSet
        }
        
        if let cdnPathBuilder = cdnPathBuilder {
            return cdnPathBuilder(cdnBaseURL, path)
        }
        
        return cdnBaseURL + path
    }
    
    /// Appends the asset's path with the base CDN URL. With support for optional
    public static func getCDNPath(optional path: String?) throws -> String? {
        guard let pathUnwrapped = path else {
            return nil
        }
        
        guard let cdnBaseURL = cdnBaseURL else {
            throw Error.cdnBaseURLNotSet
        }
        
        if let cdnPathBuilder = cdnPathBuilder {
            return cdnPathBuilder(cdnBaseURL, pathUnwrapped)
        }
        
        return cdnBaseURL + pathUnwrapped
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
