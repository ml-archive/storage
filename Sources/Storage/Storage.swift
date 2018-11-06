import Core
import HTTP
import Vapor
import Foundation

public class Storage {
    public enum Error: Swift.Error {
        case missingNetworkDriver
        case cdnBaseURLNotSet
        case missingFileName
    }

    static var cdnBaseURL: String?

    public static var cdnPathBuilder: ((String, String) -> String)?

    /**
        Uploads the given `FileEntity`.
     
        - Parameters:
            - entity: The `FileEntity` to be uploaded.
     
        - Returns: The path the file was uploaded to.
     */
    @discardableResult
    public static func upload(entity: inout FileEntity, on container: Container) throws -> Future<String> {
        let networkDriver = try container.make(NetworkDriver.self)
        return try networkDriver.upload(entity: &entity, on: container)
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
        bytes: Data,
        fileName: String? = nil,
        fileExtension: String? = nil,
        mime: String? = nil,
        folder: String? = nil,
        on container: Container
    ) throws -> Future<String> {
        var entity = FileEntity(
            bytes: bytes,
            fileName: fileName,
            fileExtension: fileExtension,
            folder: folder,
            mime: mime
        )

        return try upload(entity: &entity, on: container)
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
        folder: String? = nil,
        on container: Container
    ) throws -> Future<String> {
        let (bytes, type) = try dataURI.dataURIDecoded()
        return try upload(
            bytes: bytes,
            fileName: fileName,
            fileExtension: fileExtension,
            mime: type,
            folder: folder,
            on: container
        )
    }

    /**
        Downloads the file at `path`.
     
        - Parameters:
            - path: The path of the file to be downloaded.
     
        - Returns: The downloaded file.
     */
    public static func get(path: String, on container: Container) throws -> Future<[UInt8]> {
        let networkDriver = try container.make(NetworkDriver.self)
        return try networkDriver.get(path: path, on: container)
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
    public static func delete(path: String, on container: Container) throws -> Future<Void> {
        let networkDriver = try container.make(NetworkDriver.self)
        return try networkDriver.delete(path: path, on: container)
    }
}
