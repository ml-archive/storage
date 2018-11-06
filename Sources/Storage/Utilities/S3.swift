import Core
import Vapor
import Crypto
import Foundation

public enum Region: String {
    case usEast1 = "us-east-1"
    case usEast2 = "us-east-2"
    case usWest1 = "us-west-1"
    case usWest2 = "us-west-2"
    case euWest1 = "eu-west-1"
    case euCentral1 = "eu-central-1"
    case apSouth1 = "ap-south-1"
    case apSoutheast1 = "ap-southeast-1"
    case apSoutheast2 = "ap-southeast-2"
    case apNortheast1 = "ap-northeast-1"
    case apNortheast2 = "ap-northeast-2"
    case saEast1 = "sa-east-1"

    public var host: String {
        switch self {
        case .usEast1: return "s3.amazonaws.com"
        case .usEast2: return "s3.us-east-2.amazonaws.com"
        case .usWest1: return "s3-us-west-1.amazonaws.com"
        case .usWest2: return "s3-us-west-2.amazonaws.com"
        case .euWest1: return "s3-eu-west-1.amazonaws.com"
        case .euCentral1: return "s3.eu-central-1.amazonaws.com"
        case .apSouth1: return "s3.ap-south-1.amazonaws.com"
        case .apSoutheast1: return "s3-ap-southeast-1.amazonaws.com"
        case .apSoutheast2: return "s3-ap-southeast-2.amazonaws.com"
        case .apNortheast1: return "s3-ap-northeast-1.amazonaws.com"
        case .apNortheast2: return "s3.ap-northeast-2.amazonaws.com"
        case .saEast1: return "s3-sa-east-1.amazonaws.com"
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
    let contentType = "application/x-www-form-urlencoded; charset=utf-8"

    internal var unitTestDate: Date?

    var amzDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "YYYYMMdd'T'HHmmss'Z'"
        return dateFormatter.string(from: unitTestDate ?? Date())
    }

    public init(
        service: String,
        host: String,
        region: Region,
        accessKey: String,
        secretKey: String
        ) {
        self.service = service
        self.host = host
        self.region = region.rawValue
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
        dateFormatter.dateFormat = "YYYYMMdd"
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
        headers["X-Amz-Date"] = amzDate

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
         - method: Type of HTTP request
         - path: API call being referenced
         - query: Additional querystring in key-value format ("?key=value&key2=value2")
         - headers: HTTP headers added to the request
     */
    public func sign(
        payload: Payload = .none,
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
            "X-Amz-Date": amzDate,
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
        case invalidResponse(HTTPStatus)
    }

    let signer: AWSSignatureV4
    public var host: String

    public init(
        host: String,
        accessKey: String,
        secretKey: String,
        region: Region
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
        access: AccessControlList = .publicRead,
        on container: Container
    ) throws -> Future<Response> {
        guard let url = URL(string: generateURL(for: path)) else {
            throw Error.invalidPath
        }

        let signedHeaders = try signer.sign(
            payload: .bytes(bytes),
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
        return client.send(req)
    }
}

extension S3 {
    func generateURL(for path: String) -> String {
        return "https://\(host)\(path)"
    }
}
