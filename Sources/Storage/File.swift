import Core

public struct UploadEntity {
    var bytes: Bytes
    var fileName: String?
    var fileExtension: String?
    var folder: String?
    var mime: String?
    
    init(
        bytes: BytesRepresentable,
        fileName: String? = nil,
        fileExtension: String? = nil,
        folder: String? = nil,
        mime: String? = nil
    ) throws {
        self.bytes = try bytes.makeBytes()
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

extension UploadEntity {
    func verify() throws {
        guard fileName != nil else {
            throw Error.missingFilename
        }
        
        guard fileExtension != nil else {
            throw Error.missingFileExtension
        }
    }
}

extension UploadEntity {
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
