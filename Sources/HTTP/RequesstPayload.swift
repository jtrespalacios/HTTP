import Foundation

public protocol RequestPayload: Codable {
    static var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
}

public extension RequestPayload {
    static var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        .useDefaultKeys
    }
}
