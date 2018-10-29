import Core
import Random
import Foundation

extension UInt8 {
    /// #
    static var octothorp: UInt8 = 0x23
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
        case literal([UInt8])
        case alias(Alias)
    }
    
    var scanner: Scanner<UInt8>
    var parts: [PathPart] = []
    
    init(scanner: Scanner<UInt8>) {
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
        
        var pathUInt8s: [UInt8] = []
        
        for part in parts {
            switch part {
            case .literal(let bytes):
                pathUInt8s += bytes
            case .alias(let alias):
                switch alias {
                case .file:
                    guard let fullFileName = entity.fullFileName else {
                        throw Error.malformedFileName
                    }
                    pathUInt8s += fullFileName.bytes
                    
                case .fileName:
                    guard let fileName = entity.fileName else {
                        throw Error.fileNameNotProvided
                    }
                    pathUInt8s += fileName.bytes
                    
                case .fileExtension:
                    guard let fileExtension = entity.fileExtension else {
                        throw Error.fileExtensionNotProvided
                    }
                    pathUInt8s += fileExtension.bytes
                    
                case .folder:
                    guard let folder = entity.folder else {
                        throw Error.folderNotProvided
                    }
                    pathUInt8s += folder.bytes
                    
                case .mime:
                    guard let mime = entity.mime else {
                        throw Error.mimeNotProvided
                    }
                    pathUInt8s += mime.bytes
                    
                case .mimeFolder:
                    guard let mimeFolder = mimeFolderBuilder(entity.mime) else {
                        throw Error.mimeFolderNotProvided
                    }
                    pathUInt8s += mimeFolder.bytes
                    
                case .day:
                    guard let day = dateComponents.day else {
                        throw Error.failedToExtractDate
                    }
                    pathUInt8s += "\(day)".bytes
                    
                case .month:
                    guard let month = dateComponents.month else {
                        throw Error.failedToExtractDate
                    }
                    pathUInt8s += "\(month)".bytes
                    
                case .year:
                    guard let year = dateComponents.year else {
                        throw Error.failedToExtractDate
                    }
                    pathUInt8s += "\(year)".bytes
                    
                case .timestamp:
                    guard
                        let hours = dateComponents.hour,
                        let minutes = dateComponents.minute,
                        let seconds = dateComponents.second
                    else {
                        throw Error.failedToExtractDate
                    }
                    let time = formatTime(hours: hours, minutes: minutes, seconds: seconds)
                    pathUInt8s += time.bytes
                    
                case .uuid:
                    let uuidUInt8s = UUID().uuidString.bytes
                    pathUInt8s += uuidUInt8s
                }
            }
        }
        
        return String(bytes: pathUInt8s, encoding: .utf8) ?? ""
    }
}

extension Template {
    mutating func extractPart() throws -> PathPart? {
        guard let byte = scanner.peek() else { return nil }
        
        if byte == UInt8.octothorp {
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
        var partial: [UInt8] = []
        
        var peeked = 0
        defer { scanner.pop(peeked) }
        
        var current = Template.trie
        
        while let byte = scanner.peek(aheadBy: peeked) {
            peeked += 1
            
            guard let next = current[byte] else { break }
            
            if let value = next.value {
                if let nextUInt8 = scanner.peek(aheadBy: peeked) {
                    guard next[nextUInt8] != nil else {
                        return .alias(value)
                    }
                    partial.append(byte)
                    current = next
                    continue
                }
                
                return .alias(value)
            }
            
            partial.append(byte)
            current = next
        }

        let invalidAlias = String(bytes: partial, encoding: .utf8) ?? ""
        throw Error.invalidAlias(invalidAlias)
    }
    
    mutating func extractLiteral() -> PathPart {
        var partial: [UInt8] = []
        var peeked = 0
        defer { scanner.pop(peeked) }
        
        while
            let byte = scanner.peek(aheadBy: peeked),
            byte != UInt8.octothorp
        {
            peeked += 1
            partial.append(byte)
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
