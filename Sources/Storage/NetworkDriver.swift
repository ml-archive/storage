import S3
import Core
import Foundation

protocol NetworkDriver {
    var pathBuilder: PathBuilder { get set }
    
    @discardableResult func upload(entity: inout FileEntity) throws -> String
    func get(path: String) throws -> Bytes
    func delete(path: String) throws
}

final class S3Driver: NetworkDriver {
    enum Error: Swift.Error {
        case nilFileUpload
        case missingFileExtensionAndType
        case pathMissingForwardSlash
    }
    
    var pathBuilder: PathBuilder
    
    var s3: S3
    
    init(s3: S3, pathBuilder: PathBuilder) {
        self.pathBuilder = pathBuilder
        self.s3 = s3
    }
    
    @discardableResult
    func upload(entity: inout FileEntity) throws -> String {
        guard let bytes = entity.bytes else {
            throw Error.nilFileUpload
        }
        
        entity.sanitize()
        
        if entity.fileExtension == nil {
            guard entity.loadFileExtensionFromMime() else {
                throw Error.missingFileExtensionAndType
            }
        }
        
        if entity.mime == nil {
            guard entity.loadMimeFromFileExtension() else {
                throw Error.missingFileExtensionAndType
            }
        }
        
        let path = try pathBuilder.build(entity: entity)
        
        guard path.hasPrefix("/") else {
            print("The S3 driver requires your path to begin with `/`")
            print("Please check `template` in `storage.json`.")
            throw Error.pathMissingForwardSlash
        }
        
        try s3.upload(bytes: bytes, path: path, access: .publicRead)
        
        return path
    }
    
    func get(path: String) throws -> Bytes {
        return try s3.get(path: path)
    }
    
    func delete(path: String) throws {
        return try s3.delete(file: path)
    }
}
