import Foundation

public protocol UploadPathBuilder {
    func build(entity: UploadEntity) -> String
    func generateFolder(for mime: String?) -> String?
}

extension UploadPathBuilder {
    public func generateFolder(for mime: String?) -> String? {
        guard let mime = mime else { return nil }
        
        return mime.lowercased().hasPrefix("image") ? "images/original" : "data"
    }
}

enum PathTemplate {
    case literal(String)
    case alias(ConfigurablePathBuilder.Keyword)
}

public final class ConfigurablePathBuilder: UploadPathBuilder {
    public enum Keyword: String {
        case fileName       = "$fileName"
        case fileExtension  = "$fileExtension"
        case folder         = "$folder"
        case mimeFolder     = "$mimeFolder"
    }
    
    var template: String
    
    public init(template: String) {
        self.template = template
    }
    
    public func build(entity: UploadEntity) -> String {
        //TODO(Brett): compile template once instead of generating/replacing
        //on every single call.
        var result = template
        
        if let fileName = entity.fileName {
            result = result.replacingOccurrences(
                of: Keyword.fileName.rawValue,
                with: fileName
            )
        }
        
        if let fileExtension = entity.fileExtension {
            result = result.replacingOccurrences(
                of: Keyword.fileExtension.rawValue,
                with: fileExtension
            )
        }
        
        if let folder = entity.folder {
            result = result.replacingOccurrences(
                of: Keyword.folder.rawValue,
                with: folder
            )
        }

        if let mime = entity.mime, let mimeFolder = generateFolder(for: mime) {
            result = result.replacingOccurrences(
                of: Keyword.mimeFolder.rawValue,
                with: mimeFolder
            )
        }
        
        return result
    }
}

public protocol Uploader {
    var pathBuilder: UploadPathBuilder { get set }
    
    func upload(entity: UploadEntity) throws -> String
}

public final class S3Uploader: Uploader {
    public var pathBuilder: UploadPathBuilder
    
    public init(pathBuilder: UploadPathBuilder) {
        self.pathBuilder = pathBuilder
    }
    
    public func upload(entity: UploadEntity) throws -> String {
        //TODO(Brett): Add S3 lib and finish implementation
        return ""
    }
}
