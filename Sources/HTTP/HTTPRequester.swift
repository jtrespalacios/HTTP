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
             queryItems: [URLQueryItem]?) -> Promise<(HTTPURLResponse, Data?)>

    func get<T: Decodable>(
        _ url: String,
        queryItems: [URLQueryItem]?
    ) -> Promise<T>

    func post<T: Encodable>(
        _ url: String,
        queryItems: [URLQueryItem]?,
        payload: T
    ) -> Promise<(HTTPURLResponse, Data?)>

    func post<T: Encodable, U: Decodable>(
        _ url: String,
        queryItems: [URLQueryItem]?,
        payload: T
    ) throws -> Promise<U>

    func put<T: Encodable>(
        _ url: String,
        queryItems: [URLQueryItem]?,
        payload: T
    ) -> Promise<(HTTPURLResponse, Data?)>

    func put<T: Encodable, U: Decodable>(
        _ url: String,
        queryItems: [URLQueryItem]?,
        payload: T
    ) throws -> Promise<U>

    func delete(
        _ url: String,
        queryItems: [URLQueryItem]?
    ) -> Promise<(HTTPURLResponse, Data?)>
}
