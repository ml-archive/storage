import Foundation

/// A parser for decoding Data URIs.
public struct DataURIParser {
    enum Error: Swift.Error {
        case invalidScheme
        case invalidURI
    }

    var scanner: Scanner<UInt8>

    init(scanner: Scanner<UInt8>) {
        self.scanner = scanner
    }
}

extension DataURIParser {
    /**
     Parses a Data URI and returns its type and data.

     - Parameters:
     - uri: The URI to be parsed.

     - Returns: (data: [UInt8], type: [UInt8], typeMetadata: [UInt8]?)
     */
    public static func parse(uri: String) throws -> (Data, [UInt8], [UInt8]?) {
        guard uri.hasPrefix("data:") else {
            throw Error.invalidScheme
        }

        var scanner: Scanner<UInt8> = Scanner(uri.bytes)
        //pop scheme ("data:")
        scanner.pop(5)

        var parser = DataURIParser(scanner: scanner)
        var (type, typeMetadata) = try parser.extractType()
        var data = try parser.extractData()

        //Required by RFC 2397
        if type.isEmpty {
            type = "text/plain;charset=US-ASCII".bytes
        }

        if let typeMetadata = typeMetadata, typeMetadata == "base64".bytes {
            data = Data(base64Encoded: data) ?? Data()
        }

        return (data, type, typeMetadata)
    }
}

extension DataURIParser {
    mutating func extractType() throws -> ([UInt8], [UInt8]?) {
        let type = consume(until: [.comma, .semicolon])

        guard let byte = scanner.peek() else {
            throw Error.invalidURI
        }

        var typeMetadata: [UInt8]? = nil

        if byte == .semicolon {
            typeMetadata = try extractTypeMetadata()
        }

        return (type, typeMetadata)
    }

    mutating func extractTypeMetadata() throws -> [UInt8] {
        assert(scanner.peek() == .semicolon)
        scanner.pop()

        return consume(until: [.comma])
    }

    mutating func extractData() throws -> Data {
        assert(scanner.peek() == .comma)
        scanner.pop()
        return try Data(consumePercentDecoded())
    }
}

extension DataURIParser {
    @discardableResult
    mutating func consume() -> [UInt8] {
        var bytes: [UInt8] = []

        while let byte = scanner.peek() {
            scanner.pop()
            bytes.append(byte)
        }

        return bytes
    }

    @discardableResult
    mutating func consumePercentDecoded() throws -> [UInt8] {
        var bytes: [UInt8] = []

        while var byte = scanner.peek() {
            if byte == .percent {
                byte = try decodePercentEncoding()
            }

            scanner.pop()
            bytes.append(byte)
        }

        return bytes
    }

    @discardableResult
    mutating func consume(until terminators: Set<UInt8>) -> [UInt8] {
        var bytes: [UInt8] = []

        while let byte = scanner.peek(), !terminators.contains(byte) {
            scanner.pop()
            bytes.append(byte)
        }

        return bytes
    }

    @discardableResult
    mutating func consume(while conditional: (UInt8) -> Bool) -> [UInt8] {
        var bytes: [UInt8] = []

        while let byte = scanner.peek(), conditional(byte) {
            scanner.pop()
            bytes.append(byte)
        }

        return bytes
    }
}

extension DataURIParser {
    mutating func decodePercentEncoding() throws -> UInt8 {
        assert(scanner.peek() == .percent)

        guard
            let leftMostDigit = scanner.peek(aheadBy: 1),
            let rightMostDigit = scanner.peek(aheadBy: 2)
        else {
                throw Error.invalidURI
        }

        scanner.pop(2)

        return (leftMostDigit.asciiCode * 0x10) + rightMostDigit.asciiCode
    }
}

extension UInt8 {
    internal var asciiCode: UInt8 {
        if self >= 48 && self <= 57 {
            return self - 48
        } else if self >= 65 && self <= 70 {
            return self - 55
        } else {
            return 0
        }
    }
}

extension String {
    /**
     Parses a Data URI and returns its data and type.

     - Returns: The type of the file and its data as bytes.
     */
    public func dataURIDecoded() throws -> (data: Data, type: String) {
        let (data, type, _) = try DataURIParser.parse(uri: self)
        return (data, String(bytes: type, encoding: .utf8) ?? "")
    }
}
