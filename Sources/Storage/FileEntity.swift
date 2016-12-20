import Core

/// Representation of a to-be-uploaded file.
public struct FileEntity {
    public enum Error : Swift.Error {
        case missingFilename
        case missingFileExtension
    }
    
    //TODO(Brett): considering changing all `String` fields to `Bytes`.
    
    /// The raw bytes of the file.
    var bytes: Bytes?
    
    /// The file's name.
    var fileName: String?
    
    /// The file's extension.
    var fileExtension: String?
    
    /// The folder the file was uploaded from.
    var folder: String?
    
    /// The type of the file.
    var mime: String?
    
    /**
        FileEntity's default initializer.
     
        - Parameters:
            - bytes: The raw bytes of the file.
            - fileName: The file's name.
            - fileExtension: The file's extension.
            - folder: The folder the file was uploaded from.
            - mime: The type of the file.
     */
    public init(
        bytes: Bytes? = nil,
        fileName: String? = nil,
        fileExtension: String? = nil,
        folder: String? = nil,
        mime: String? = nil
    ) {
        self.bytes = bytes
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.folder = folder
        self.mime = mime
    }
}

extension FileEntity {
    func verify() throws {
        guard fileName != nil else {
            throw Error.missingFilename
        }
        
        guard fileExtension != nil else {
            throw Error.missingFileExtension
        }
    }
}

extension FileEntity {
    func getFilePath() throws -> String {
        guard let fileName = fileName else {
            throw Error.missingFilename
        }
        
        guard let fileExtension = fileExtension else {
            throw Error.missingFileExtension
        }
        
        var path = [
            "\(fileName).\(fileExtension)"
        ]
        
        if let folder = folder {
            path.insert(folder, at: 0)
        }
        
        return path.joined(separator: "/")
    }
}
