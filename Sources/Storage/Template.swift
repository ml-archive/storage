import Core
import Random
import Foundation

extension Byte {
    /// #
    static var octothorp: Byte = 0x23
}

struct Template {
    let calendar = Calendar(identifier: .gregorian)
    
    enum Error: Swift.Error {
        case invalidAlias(String)
        case failedToExtractDate
        case malformedFileName
        case fileNameNotProvided
        case fileExtensionNotProvided
        case folderNotProvided
        case mimeNotProvided
        case mimeFolderNotProvided
    }
    
    enum Alias: String {
        case file           = "#file"
        case fileName       = "#fileName"
        case fileExtension  = "#fileExtension"
        case folder         = "#folder"
        case mime           = "#mime"
        case mimeFolder     = "#mimeFolder"
        case day            = "#day"
        case month          = "#month"
        case year           = "#year"
        case timestamp      = "#timestamp"
        case uuid           = "#uuid"
    }
    
    enum PathPart {
        case literal(Bytes)
        case alias(Alias)
    }
    
    var scanner: Scanner<Byte>
    var parts: [PathPart] = []
    
    init(scanner: Scanner<Byte>) {
        self.scanner = scanner
    }
}

extension Template {
    static func compile(_ templateString: String) throws -> Template {
        var template = Template(scanner: Scanner(templateString.bytes))
        
        while let part = try template.extractPart() {
            template.parts.append(part)
        }
        
        return template
    }
    
    func renderPath(
        for entity: FileEntity,
        _ mimeFolderBuilder: (String?) -> String?
    ) throws -> String {
        let dateComponents = getDateComponents()
        
        var pathBytes: [Byte] = []
        
        for part in parts {
            switch part {
            case .literal(let bytes):
                pathBytes += bytes
            case .alias(let alias):
                switch alias {
                case .file:
                    guard let fullFileName = entity.fullFileName else {
                        throw Error.malformedFileName
                    }
                    pathBytes += fullFileName.bytes
                    
                case .fileName:
                    guard let fileName = entity.fileName else {
                        throw Error.fileNameNotProvided
                    }
                    pathBytes += fileName.bytes
                    
                case .fileExtension:
                    guard let fileExtension = entity.fileExtension else {
                        throw Error.fileExtensionNotProvided
                    }
                    pathBytes += fileExtension.bytes
                    
                case .folder:
                    guard let folder = entity.folder else {
                        throw Error.folderNotProvided
                    }
                    pathBytes += folder.bytes
                    
                case .mime:
                    guard let mime = entity.mime else {
                        throw Error.mimeNotProvided
                    }
                    pathBytes += mime.bytes
                    
                case .mimeFolder:
                    guard let mimeFolder = mimeFolderBuilder(entity.mime) else {
                        throw Error.mimeFolderNotProvided
                    }
                    pathBytes += mimeFolder.bytes
                    
                case .day:
                    guard let day = dateComponents.day else {
                        throw Error.failedToExtractDate
                    }
                    pathBytes += "\(day)".bytes
                    
                case .month:
                    guard let month = dateComponents.month else {
                        throw Error.failedToExtractDate
                    }
                    pathBytes += "\(month)".bytes
                    
                case .year:
                    guard let year = dateComponents.year else {
                        throw Error.failedToExtractDate
                    }
                    pathBytes += "\(year)".bytes
                    
                case .timestamp:
                    guard
                        let hours = dateComponents.hour,
                        let minutes = dateComponents.minute,
                        let seconds = dateComponents.second
                    else {
                        throw Error.failedToExtractDate
                    }
                    let time = formatTime(hours: hours, minutes: minutes, seconds: seconds)
                    pathBytes += time.bytes
                    
                case .uuid:
                    let uuidBytes = UUID().uuidString.bytes
                    pathBytes += uuidBytes
                }
            }
        }
        
        return try String(bytes: pathBytes)
    }
}

extension Template {
    mutating func extractPart() throws -> PathPart? {
        guard let byte = scanner.peek() else { return nil }
        
        if byte == Byte.octothorp {
            return try extractAlias()
        } else {
            return extractLiteral()
        }
    }
}

extension Template {
    //convenience for adding aliases to trie
    static func insert(into trie: Trie<Alias>, _ alias: Template.Alias) {
        trie.insert(alias, for: alias.rawValue.bytes)
    }
}

extension Template {
    static let trie: Trie<Alias> = {
        let _trie = Trie<Alias>()
        insert(into: _trie, Alias.file)
        insert(into: _trie, Alias.fileName)
        insert(into: _trie, Alias.fileExtension)
        insert(into: _trie, Alias.folder)
        insert(into: _trie, Alias.mime)
        insert(into: _trie, Alias.mimeFolder)
        insert(into: _trie, Alias.day)
        insert(into: _trie, Alias.month)
        insert(into: _trie, Alias.year)
        insert(into: _trie, Alias.timestamp)
        insert(into: _trie, Alias.uuid)
        return _trie
    }()
    
    mutating func extractAlias() throws -> PathPart {
        var partial: [Byte] = []
        
        var peeked = 0
        defer { scanner.pop(peeked) }
        
        var current = Template.trie
        
        while let byte = scanner.peek(aheadBy: peeked) {
            peeked += 1
            
            guard let next = current[byte] else { break }
            
            if let value = next.value {
                if let nextByte = scanner.peek(aheadBy: peeked) {
                    guard next[nextByte] != nil else {
                        return .alias(value)
                    }
                    partial += byte
                    current = next
                    continue
                }
                
                return .alias(value)
            }
            
            partial += byte
            current = next
        }

        let invalidAlias = try String(bytes: partial)
        throw Error.invalidAlias(invalidAlias)
    }
    
    mutating func extractLiteral() -> PathPart {
        var partial: [Byte] = []
        var peeked = 0
        defer { scanner.pop(peeked) }
        
        while
            let byte = scanner.peek(aheadBy: peeked),
            byte != Byte.octothorp
        {
            peeked += 1
            partial += byte
        }
        
        return .literal(partial)
    }
}

extension Template {
    func getDateComponents() -> DateComponents {
        return calendar.dateComponents(
            [.day, .month, .year, .second, .minute, .hour],
            from: Date()
        )
    }
    
    func padDigitLeft(_ digit: Int) -> String {
        return digit < 10 ? "0\(digit)" : "\(digit)"
    }
    
    func formatTime(hours: Int, minutes: Int, seconds: Int) -> String {
        let hours = padDigitLeft(hours)
        let minutes = padDigitLeft(minutes)
        let seconds = padDigitLeft(seconds)
        
        return "\(hours):\(minutes):\(seconds)"
    }
}

extension Template.Error: Equatable {
    static func ==(lhs: Template.Error, rhs: Template.Error) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAlias, .invalidAlias),
             (.malformedFileName, .malformedFileName),
             (.failedToExtractDate, .failedToExtractDate),
             (.fileNameNotProvided, .fileNameNotProvided),
             (.fileExtensionNotProvided, .fileExtensionNotProvided),
             (.folderNotProvided, .folderNotProvided),
             (.mimeNotProvided, .mimeNotProvided),
             (.mimeFolderNotProvided, .mimeFolderNotProvided):
            return true
            
        default:
            return false
        }
    }
}

extension Template.PathPart: Equatable {
    static func ==(lhs: Template.PathPart, rhs: Template.PathPart) -> Bool {
        switch (lhs, rhs) {
        case (.literal(let a), literal(let b)):
            return a == b
            
        case (.alias(let a), .alias(let b)):
            return a == b
            
        default:
            return false
        }
    }
}
