//
//  File.swift
//
//
//  Created by Jeffery Trespalacios on 1/21/20.
//

import Foundation

protocol ResponsePayload: Codable {
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }
}

extension ResponsePayload {
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        return .useDefaultKeys
    }
}
