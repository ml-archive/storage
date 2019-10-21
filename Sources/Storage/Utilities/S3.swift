import Core
import Vapor
import Crypto
import Foundation

extension S3 {
    public struct Region {
      let code: String

      public static var usEast1: Region = .init(code: "us-east-1")
      public static var usEast2: Region = .init(code: "us-east-2")
      public static var usWest1: Region = .init(code: "us-west-1")
      public static var usWest2: Region = .init(code: "us-west-2")
      public static var euWest1: Region = .init(code: "eu-west-1")
      public static var euWest2: Region = .init(code: "eu-west-2")
      public static var euWest3: Region = .init(code: "eu-west-3")
      public static var euCentral1: Region = .init(code: "eu-central-1")
      public static var apSouth1: Region = .init(code: "ap-south-1")
      public static var apSoutheast1: Region = .init(code: "ap-southeast-1")
      public static var apSoutheast2: Region = .init(code: "ap-southeast-2")
      public static var apNortheast1: Region = .init(code: "ap-northeast-1")
      public static var apNortheast2: Region = .init(code: "ap-northeast-2")
      public static var saEast1: Region = .init(code: "sa-east-1")

      public init(code: String) {
        self.code = code
      }

      public var host: String {
        return "s3-\(code).amazonaws.com"
      }
    }
}

public enum Payload {
    case bytes(Data)
    case unsigned
    case none
}

extension Payload {
    func hashed() throws -> String {
        switch self {
        case .bytes(let bytes):
            return try SHA256.hash(bytes).hexEncodedString()

        case .unsigned:
            return "UNSIGNED-PAYLOAD"

        case .none:
            // SHA256 hash of ''
            return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        }
    }
}

extension Payload {
    var bytes: Data {
        switch self {
        case .bytes(let bytes):
            return bytes

        default:
            return Data()
        }
    }
}

extension String {
    public static let awsQueryAllowed = CharacterSet(
        charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-._~=&"
    )

    public static let awsPathAllowed = CharacterSet(
        charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-._~/"
    )
}

public enum AccessControlList: String {
    case privateAccess = "private"
    case publicRead = "public-read"
    case publicReadWrite = "public-read-write"
    case awsExecRead = "aws-exec-read"
    case authenticatedRead = "authenticated-read"
    case bucketOwnerRead = "bucket-owner-read"
    case bucketOwnerFullControl = "bucket-owner-full-control"
}

public struct AWSSignatureV4 {
    public enum Method: String {
        case delete = "DELETE"
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    let service: String
    let host: String
    let region: String
    let accessKey: String
    let secretKey: String

    internal var unitTestDate: Date?

    var amzDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return dateFormatter.string(from: unitTestDate ?? Date())
    }

    public init(
        service: String,
        host: String,
        region: S3.Region,
        accessKey: String,
        secretKey: String
    ) {
        self.service = service
        self.host = host
        self.region = region.code
        self.accessKey = accessKey
        self.secretKey = secretKey
    }

    func getStringToSign(
        algorithm: String,
        date: String,
        scope: String,
        canonicalHash: String
    ) -> String {
        return [
            algorithm,
            date,
            scope,
            canonicalHash
        ].joined(separator: "\n")
    }

    func getSignature(_ stringToSign: String) throws -> String {
        let dateHMAC = try HMAC.SHA256.authenticate(dateStamp(), key: "AWS4\(secretKey)")
        let regionHMAC = try HMAC.SHA256.authenticate(region, key: dateHMAC)
        let serviceHMAC = try HMAC.SHA256.authenticate(service, key: regionHMAC)
        let signingHMAC = try HMAC.SHA256.authenticate("aws4_request", key: serviceHMAC)

        let signature = try HMAC.SHA256.authenticate(stringToSign, key: signingHMAC)
        return signature.hexEncodedString()
    }

    func getCredentialScope() -> String {
        return [
            dateStamp(),
            region,
            service,
            "aws4_request"
        ].joined(separator: "/")
    }

    func getCanonicalRequest(
        payloadHash: String,
        method: Method,
        path: String,
        query: String,
        canonicalHeaders: String,
        signedHeaders: String
    ) throws -> String {
        let path = path.addingPercentEncoding(withAllowedCharacters: String.awsPathAllowed) ?? ""
        let query = query.addingPercentEncoding(withAllowedCharacters: String.awsQueryAllowed) ?? ""
        return [
            method.rawValue,
            path,
            query,
            canonicalHeaders,
            "",
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")
    }

    func dateStamp() -> String {
        let date = unitTestDate ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: date)
    }
}

extension AWSSignatureV4 {
    func generateHeadersToSign(
        headers: inout [String: String],
        host: String,
        hash: String
    ) {
        headers["Host"] = host
        headers["x-amz-date"] = amzDate

        if hash != "UNSIGNED-PAYLOAD" {
            headers["x-amz-content-sha256"] = hash
        }
    }

    func alphabetize(_ dict: [String: String]) -> [(key: String, value: String)] {
        return dict.sorted(by: { $0.0.lowercased() < $1.0.lowercased() })
    }

    func createCanonicalHeaders(_ headers: [(key: String, value: String)]) -> String {
        return headers.map {
            "\($0.key.lowercased()):\($0.value)"
        }.joined(separator: "\n")
    }

    func createAuthorizationHeader(
        algorithm: String,
        credentialScope: String,
        signature: String,
        signedHeaders: String
    ) -> String {
        return "\(algorithm) Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
    }
}

extension AWSSignatureV4 {
    /**
         Sign a request to be sent to an AWS API.
         - returns:
         A dictionary with headers to attach to a request
         - parameters:
         - payload: A hash of this data will be included in the headers
         - contentType: Mime type of file
         - method: Type of HTTP request
         - path: API call being referenced
         - query: Additional querystring in key-value format ("?key=value&key2=value2")
         - headers: HTTP headers added to the request
     */
    public func sign(
        payload: Payload = .none,
        contentType: String,
        method: Method = .get,
        path: String,
        query: String? = nil,
        headers: [String: String] = [:]
    ) throws -> [String: String] {
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = getCredentialScope()
        let payloadHash = try payload.hashed()

        var headers = headers

        generateHeadersToSign(headers: &headers, host: host, hash: payloadHash)

        let sortedHeaders = alphabetize(headers)
        let signedHeaders = sortedHeaders.map { $0.key.lowercased() }.joined(separator: ";")
        let canonicalHeaders = createCanonicalHeaders(sortedHeaders)

        let canonicalRequest = try getCanonicalRequest(
            payloadHash: payloadHash,
            method: method,
            path: path,
            query: query ?? "",
            canonicalHeaders: canonicalHeaders,
            signedHeaders: signedHeaders
        )

        let canonicalHash = try SHA256.hash(canonicalRequest).hexEncodedString()

        let stringToSign = getStringToSign(
            algorithm: algorithm,
            date: amzDate,
            scope: credentialScope,
            canonicalHash: canonicalHash
        )

        let signature = try getSignature(stringToSign)

        let authorizationHeader = createAuthorizationHeader(
            algorithm: algorithm,
            credentialScope: credentialScope,
            signature: signature,
            signedHeaders: signedHeaders
        )

        var requestHeaders: [String: String] = [
            "x-amz-date": amzDate,
            "Content-Type": contentType,
            "x-amz-content-sha256": payloadHash,
            "Authorization": authorizationHeader,
            "Host": host
        ]

        headers.forEach { key, value in
            requestHeaders[key] = value
        }

        return requestHeaders
    }
}

public struct S3: Service {
    public enum Error: Swift.Error {
        case unimplemented
        case invalidPath
        case invalidResponse(status: HTTPStatus, reason: String)
    }

    let signer: AWSSignatureV4
    public var host: String

    public init(
        host: String,
        accessKey: String,
        secretKey: String,
        region: S3.Region
    ) {
        self.host = host
        signer = AWSSignatureV4(
            service: "s3",
            host: host,
            region: region,
            accessKey: accessKey,
            secretKey: secretKey
        )
    }

    public func upload(
        bytes: Data,
        path: String,
        contentType: String = "application/x-www-form-urlencoded; charset=utf-8",
        access: AccessControlList = .publicRead,
        on container: Container
    ) throws -> Future<Response> {
        guard let url = URL(string: generateURL(for: path)) else {
            throw Error.invalidPath
        }

        let signedHeaders = try signer.sign(
            payload: .bytes(bytes),
            contentType: contentType,
            method: .put,
            path: path,
            headers: ["x-amz-acl": access.rawValue]
        )

        var headers: HTTPHeaders = [:]
        signedHeaders.forEach {
            headers.add(name: $0.key, value: $0.value)
        }

        let client = try container.client()
        let req = Request(using: container)
        req.http.method = .PUT
        req.http.headers = headers
        req.http.body = HTTPBody(data: bytes)
        req.http.url = url
        return client.send(req).map { res in
            let http = res.http
            guard http.status == .ok else {
                throw Error.invalidResponse(status: http.status, reason: http.body.description)
            }
            return res
        }
    }
    
    public func get(
        path: String,
        contentType: String = "application/x-www-form-urlencoded; charset=utf-8",
        access: AccessControlList = .publicRead,
        on container: Container
    ) throws -> Future<Response> {
        guard let url = URL(string: generateURL(for: path)) else {
            throw Error.invalidPath
        }

        let signedHeaders = try signer.sign(
            contentType: contentType,
            method: .get,
            path: path,
            headers: ["x-amz-acl": access.rawValue]
        )

        var headers: HTTPHeaders = [:]
        signedHeaders.forEach {
            headers.add(name: $0.key, value: $0.value)
        }

        let client = try container.client()
        let req = Request(using: container)
        req.http.method = .GET
        req.http.headers = headers
        req.http.url = url
        return client.send(req)
    }
}

extension S3 {
    func generateURL(for path: String) -> String {
        return "https://\(host)\(path)"
    }
}
