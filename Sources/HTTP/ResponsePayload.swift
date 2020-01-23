import Foundation

public protocol ResponsePayload: Codable {
    static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }
}

public extension ResponsePayload {
    static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        .useDefaultKeys
    }
}
