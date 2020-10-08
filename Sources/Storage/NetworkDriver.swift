import Core
import Vapor
import Foundation

public protocol NetworkDriver: Service {
    var pathBuilder: PathBuilder { get set }

    func upload(entity: inout FileEntity, access: AccessControlList, on container: Container) throws -> Future<String>
    func get(path: String, on container: Container) throws -> Future<Response>
    func delete(path: String, on container: Container) throws -> Future<Response>
}

public final class S3Driver: NetworkDriver {
    public enum Error: Swift.Error {
        case nilFileUpload
        case missingFileExtensionAndType
        case pathMissingForwardSlash
    }

    public var pathBuilder: PathBuilder
    let s3: S3

    public init(
        bucket: String,
        host: String = "s3.amazonaws.com",
        accessKey: String,
        secretKey: String,
        region: S3.Region = .euWest1,
        pathTemplate: String = ""
    ) throws {
        self.pathBuilder = try ConfigurablePathBuilder(template: pathTemplate)
        self.s3 = S3(
            host: "\(bucket).\(host)",
            accessKey: accessKey,
            secretKey: secretKey,
            region: region
        )
    }

    public func upload(
        bytes: Data,
        fileName: String? = nil,
        fileExtension: String? = nil,
        mime: String? = nil,
        folder: String? = nil,
        access: AccessControlList = .publicRead,
        on container: Container
    ) throws -> Future<String> {
        var entity = FileEntity(
            bytes: bytes,
            fileName: fileName,
            fileExtension: fileExtension,
            folder: folder,
            mime: mime
        )

        return try upload(entity: &entity, access: access, on: container)
    }

    public func upload(
        entity: inout FileEntity,
        access: AccessControlList = .publicRead,
        on container: Container
    ) throws -> Future<String> {
        guard let bytes = entity.bytes else {
            throw Error.nilFileUpload
        }

        entity.sanitize()

        guard entity.fileExtension != nil || entity.loadFileExtensionFromMime() else {
            throw Error.missingFileExtensionAndType
        }

        if entity.mime == nil {
            entity.loadMimeFromFileExtension()
        }
        
        guard let mime = entity.mime else {
            throw Error.missingFileExtensionAndType
        }

        let path = try pathBuilder.build(entity: entity)

        guard path.hasPrefix("/") else {
            print("The S3 driver requires your path to begin with `/`")
            print("Please check `template` in `storage.json`.")
            throw Error.pathMissingForwardSlash
        }

        return try s3.upload(
            bytes: Data(bytes),
            path: path,
            contentType: mime,
            access: access,
            on: container
        ).transform(to: path)
    }

    public func get(path: String, on container: Container) throws -> Future<Response> {
        return try s3.get(path: path, on: container).map { $0 }
    }

    public func delete(path: String, on container: Container) throws -> Future<Response> {
        return try s3.delete(path: path, on: container).map { $0 }
    }
}
