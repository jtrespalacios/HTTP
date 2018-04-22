//
//  HTTPRequester.swift
//  HTTP
//
//  Created by Jeffery Trespalacios on 4/21/18.
//

import Foundation
import PromiseKit

public protocol HTTPRequester {

  var session: URLSessionProtocol { get }

  func send(_ request: Requestable) -> Promise<(HTTPURLResponse, Data?)>

  func get(url: String,
           params: [(String, String?)]?) -> Promise<(HTTPURLResponse, Data?)>
  func get<T: Decodable>(_ url: String,
                         params: [(String, String?)]?) -> Promise<T>

  func post<T: Encodable>(_ url: String,
                          params: [(String, String?)]?,
                          payload: T) -> Promise<(HTTPURLResponse, Data?)>
  func post<T: Encodable, U: Decodable>(_ url: String,
                                        params: [(String, String?)]?,
                                        payload: T) throws -> Promise<U>

  func put<T: Encodable>(_ url: String,
                         params: [(String, String?)]?,
                         payload: T) -> Promise<(HTTPURLResponse, Data?)>
  func put<T: Encodable, U: Decodable>(_ url: String,
                                       params: [(String, String?)]?,
                                       payload: T) throws -> Promise<U>

  func delete(_ url: String,
              params: [(String, String?)]?) -> Promise<(HTTPURLResponse, Data?)>
}
