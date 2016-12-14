struct Settings {
    let fileName: String?
    let fileExtension: String?
    let folder: String?
    
    init(fileName: String? = nil, fileExtension: String? = nil, folder: String? = nil) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.folder = folder
    }
    
    enum Error : Swift.Error {
        case missingFilename
        case missingFileExtension
    }
}

extension Settings {
    func verify() throws {
        guard fileName != nil else {
            throw Error.missingFilename
        }
        
        guard fileExtension != nil else {
            throw Error.missingFileExtension
        }
    }
}

extension Settings {
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
