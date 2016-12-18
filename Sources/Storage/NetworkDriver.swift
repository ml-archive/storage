import S3
import Core
import Foundation

public protocol NetworkDriver {
    var pathBuilder: PathBuilder { get set }
    
    func upload(entity: FileEntity) throws
    func get(entity: FileEntity) throws -> Data
    func delete(entity: FileEntity) throws
}

public final class S3Driver: NetworkDriver {
    public enum Error: Swift.Error {
        case nilFileUpload
    }
    
    public var pathBuilder: PathBuilder
    
    var s3: S3
    
    public init(s3: S3, pathBuilder: PathBuilder) {
        self.pathBuilder = pathBuilder
        self.s3 = s3
    }
    
    public func upload(entity: FileEntity) throws {
        guard let bytes = entity.bytes else {
            throw Error.nilFileUpload
        }
        
        let path = try pathBuilder.build(entity: entity)
        try s3.put(bytes: bytes, filePath: path)
    }
    
    public func get(entity: FileEntity) throws -> Data {
        let path = try pathBuilder.build(entity: entity)
        return try s3.get(fileAtPath: path)
    }
    
    public func delete(entity: FileEntity) throws {
        let path = try pathBuilder.build(entity: entity)
        return try s3.delete(fileAtPath: path)
    }
}
