//
//  File.swift
//  
//
//  Created by Jeffery Trespalacios on 1/21/20.
//

import Foundation

protocol HTTPResponse: Codable {
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }
}

extension HTTPResponse {
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        return .useDefaultKeys
    }
}
