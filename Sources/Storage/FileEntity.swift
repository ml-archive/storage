import Core

/// Representation of a to-be-uploaded file.
public struct FileEntity {
    public enum Error: Swift.Error {
        case missingFilename
        case missingFileExtension
        case malformedFileName
    }

    /// The raw bytes of the file.
    var bytes: Data?

    // The file's name with the extension.
    var fullFileName: String? {
        guard let fileName = fileName, let fileExtension = fileExtension else {
            return nil
        }

        return [fileName, fileExtension].joined(separator: ".")
    }

    /// The file's name without the extension.
    var fileName: String?

    /// The file's extension.
    var fileExtension: String?

    /// The folder the file was uploaded from.
    var folder: String?

    /// The type of the file.
    var mime: String?

    /// The ACL
    var access: AccessControlList

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
        bytes: Data? = nil,
        fileName: String? = nil,
        fileExtension: String? = nil,
        folder: String? = nil,
        mime: String? = nil,
        access: AccessControlList = .publicRead
    ) {
        self.bytes = bytes
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.folder = folder
        self.mime = mime
        self.access = access
        sanitize()
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
        guard let fileName = fullFileName else {
            throw Error.malformedFileName
        }

        var path = [
            fileName
        ]

        if let folder = folder {
            path.insert(folder, at: 0)
        }

        return path.joined(separator: "/")
    }
}

extension FileEntity {
    mutating func sanitize() {
        guard let fileName = fileName, fileName.contains(".") else { return }

        let components = fileName.components(separatedBy: ".")

        // don't override if a programmer provided an extension
        if fileExtension == nil {
            fileExtension = components.last
        }

        self.fileName = components.dropLast().joined(separator: ".")
    }

    @discardableResult
    mutating func loadMimeFromFileExtension() -> Bool {
        guard let fileExtension = fileExtension?.lowercased() else { return false }

        // MimeLib doesn't support `jpg` so do a check here first
        guard fileExtension != "jpg" else {
            self.mime = "image/jpeg"
            return true
        }

        guard let mime = getMime(for: fileExtension) else {
            return false
        }

        self.mime = mime
        return true
    }

    @discardableResult
    mutating func loadFileExtensionFromMime() -> Bool {
        guard let mime = mime else { return false }

        guard let fileExtension = getExtension(for: mime) else {
            return false
        }

        self.fileExtension = fileExtension
        return true
    }
}
