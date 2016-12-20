import Core

public struct FileEntity {
    //TODO(Brett): considering changing all `String` fields to `Bytes`.
    var bytes: Bytes?
    var fileName: String?
    var fileExtension: String?
    var folder: String?
    var mime: String?
    
    init(
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
    
    enum Error : Swift.Error {
        case missingFilename
        case missingFileExtension
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
