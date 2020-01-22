//
//  File.swift
//
//
//  Created by Jeffery Trespalacios on 1/21/20.
//

import Foundation

public protocol ResponsePayload: Codable {
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }
}

public extension ResponsePayload {
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        return .useDefaultKeys
    }
}
