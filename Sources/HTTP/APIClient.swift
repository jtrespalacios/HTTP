//
//  APIClient.swift
//  HTTP
//

import Foundation
import PromiseKit

public protocol RequestableRoute {
    var path: String { get }
    var method: HTTPRequest.Method { get }
    var queryItems: [URLQueryItem]? { get }
    var identifier: String? { get }
}

public protocol RequestableUploadRoute: RequestableRoute {
    associatedtype Payload: Encodable
    var payload: Payload { get }
}

public protocol APIClientConfig {
    var host: String { get }
    var headers: [(key: String, value: String)] { get }
}

open class APIClient: HTTPClientDelegate {
    enum APIClientError: Error {
        case invalidHost
    }

    public let httpClient: HTTPClient
    public let config: APIClientConfig

    public required init(
        config: APIClientConfig,
        session: URLSessionProtocol = URLSession(configuration: .default)
    ) throws {
        self.config = config
        httpClient = HTTPClient(session: session)
        httpClient.delegate = self
        try validateConfig()
    }

    public required init(
        config: APIClientConfig,
        sessionConfig: URLSessionConfiguration,
        resolutionQueue: OperationQueue = .main
    ) throws {
        self.config = config
        httpClient = HTTPClient(sessionConfig: sessionConfig, queue: resolutionQueue)
        httpClient.delegate = self
        try validateConfig()
    }

    open func willSend(request: inout Requestable) throws {
        var request = request
        for header in config.headers {
            request.request.addValue(header.value,
                                     forHTTPHeaderField: header.key)
        }
    }

    public func send<T: Decodable>(_ requestableRoute: RequestableRoute) throws -> Promise<T> {
        let requestable = try HTTPRequest.generateRequest(config.host,
                                                          path: requestableRoute.path,
                                                          queryItems: requestableRoute.queryItems,
                                                          method: requestableRoute.method,
                                                          identifier: requestableRoute.identifier)
        return httpClient.sendDecodableRequest(requestable)
    }

    public func send<T: Decodable, U: RequestableUploadRoute>(_ requestableRoute: U) throws -> Promise<T> {
        let requestable = try HTTPRequest.generateRequest(config.host,
                                                          path: requestableRoute.path,
                                                          queryItems: requestableRoute.queryItems,
                                                          payload: requestableRoute.payload,
                                                          method: requestableRoute.method,
                                                          identifier: requestableRoute.identifier)
        return httpClient.sendDecodableRequest(requestable)
    }

    open func get<T: Decodable>(_ path: String,
                                queryItems: [URLQueryItem]? = nil,
                                identifier: String? = nil) throws -> Promise<T> {
        let request = try HTTPRequest.generateRequest(config.host, path: path, queryItems: queryItems, identifier: identifier)
        return httpClient.sendDecodableRequest(request)
    }

    open func put<T: Encodable, U: Decodable>(_ path: String,
                                              payload: T,
                                              queryItems: [URLQueryItem]? = nil,
                                              identifier: String? = nil) throws -> Promise<U> {
        let request = try HTTPRequest.generateRequest(config.host,
                                                      path: path,
                                                      queryItems: queryItems,
                                                      payload: payload,
                                                      method: .put,
                                                      identifier: identifier)
        return httpClient.sendDecodableRequest(request)
    }

    open func post<T: Encodable, U: Decodable>(_ path: String,
                                               payload: T,
                                               queryItems: [URLQueryItem]? = nil,
                                               identifier: String? = nil) throws -> Promise<U> {
        let request = try HTTPRequest.generateRequest(config.host,
                                                      path: path,
                                                      queryItems: queryItems,
                                                      payload: payload,
                                                      method: .post,
                                                      identifier: identifier)
        return httpClient.sendDecodableRequest(request)
    }

    open func delete(_ path: String,
                     queryItems: [URLQueryItem]? = nil,
                     identifier: String? = nil) throws -> Promise<(HTTPURLResponse, Data?)> {
        let request = try HTTPRequest.generateRequest(config.host,
                                                      path: path,
                                                      queryItems: queryItems,
                                                      method: .delete,
                                                      identifier: identifier)
        return httpClient.send(request)
    }

    private func validateConfig() throws {
        let host = URL(string: config.host)
        if host == nil || !(host?.scheme ?? "").starts(with: "http") {
            throw APIClientError.invalidHost
        }
    }
}
