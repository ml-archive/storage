import S3
import Core
import Foundation

public protocol NetworkDriver {
    var pathBuilder: PathBuilder { get set }
    
    @discardableResult func upload(entity: FileEntity) throws -> String
    func get(path: String) throws -> Data
    func delete(path: String) throws
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
    
    @discardableResult
    public func upload(entity: FileEntity) throws -> String {
        guard let bytes = entity.bytes else {
            throw Error.nilFileUpload
        }
        
        let path = try pathBuilder.build(entity: entity)
        try s3.put(bytes: bytes, filePath: path, accessControl: .publicRead)
        
        return path
    }
    
    public func get(path: String) throws -> Data {
        return try s3.get(fileAtPath: path)
    }
    
    public func delete(path: String) throws {
        return try s3.delete(fileAtPath: path)
    }
}
