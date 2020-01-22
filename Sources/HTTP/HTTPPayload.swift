//
//  File.swift
//  
//
//  Created by Jeffery Trespalacios on 1/21/20.
//

import Foundation

public protocol HTTPPayload: Codable {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
}

public extension HTTPPayload {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return .useDefaultKeys
    }
}
