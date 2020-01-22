//
//  File.swift
//
//
//  Created by Jeffery Trespalacios on 1/21/20.
//

import Foundation

public protocol RequesstPayload: Codable {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
}

public extension RequesstPayload {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return .useDefaultKeys
    }
}
