//
//  File.swift
//
//
//  Created by Jeffery Trespalacios on 1/21/20.
//

import Foundation

public protocol ResponsePayload: Codable {
    static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }
}

public extension ResponsePayload {
    static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        return .useDefaultKeys
    }
}
