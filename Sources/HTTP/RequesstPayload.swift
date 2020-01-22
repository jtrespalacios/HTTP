//
//  File.swift
//
//
//  Created by Jeffery Trespalacios on 1/21/20.
//

import Foundation

public protocol RequestPayload: Codable {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
}

public extension RequestPayload {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return .useDefaultKeys
    }
}
