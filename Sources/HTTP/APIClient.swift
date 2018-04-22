//
//  APIClient.swift
//  HTTP
//

import Foundation
import PromiseKit

public protocol RequestableRoute {
  var path: String { get }
  var method: HTTPRequest.Method { get }
  var params: [(String, String?)]? { get }
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

  public let httpClient: HTTPClient
  public let config: APIClientConfig

  public required init(config: APIClientConfig, session: URLSessionProtocol) throws {
    self.config = config
    httpClient = HTTPClient(session: session)
    httpClient.delegate = self
  }

  public required init(config: APIClientConfig, sessionConfig: URLSessionConfiguration, resolutionQueue: OperationQueue = OperationQueue()) throws {
    self.config = config
    httpClient = HTTPClient(sessionConfig: sessionConfig, queue: resolutionQueue)
    httpClient.delegate = self
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
                                                      params: requestableRoute.params,
                                                      method: requestableRoute.method,
                                                      identifier: requestableRoute.identifier)
    return httpClient.sendDecodableRequest(requestable)
  }

  public func send<T: Decodable, U: RequestableUploadRoute>(_ requestableRoute: U) throws -> Promise<T> {
    let requestable = try HTTPRequest.generateRequest(config.host,
                                                      path: requestableRoute.path,
                                                      params: requestableRoute.params,
                                                      payload: requestableRoute.payload,
                                                      method: requestableRoute.method,
                                                      identifier: requestableRoute.identifier)
    return httpClient.sendDecodableRequest(requestable)
  }

  open func get<T: Decodable>(_ path: String,
                              params: [(String, String?)]? = nil,
                              identifier: String? = nil) throws -> Promise<T> {
    let request = try HTTPRequest.generateRequest(config.host, path: path, params: params, identifier: identifier)
    return httpClient.sendDecodableRequest(request)
  }

  open func put<T: Encodable, U: Decodable>(_ path: String,
                                            payload: T,
                                            params: [(String, String?)]? = nil,
                                            identifier: String? = nil) throws -> Promise<U> {
    let request = try HTTPRequest.generateRequest(config.host,
                                                  path: path,
                                                  params: params,
                                                  payload: payload,
                                                  method: .put,
                                                  identifier: identifier)
    return httpClient.sendDecodableRequest(request)
  }

  open func post<T: Encodable, U: Decodable>(_ path: String,
                                             payload: T,
                                             params: [(String, String?)]? = nil,
                                             identifier: String? = nil) throws -> Promise<U> {
    let request = try HTTPRequest.generateRequest(config.host,
                                                  path: path,
                                                  params: params,
                                                  payload: payload,
                                                  method: .post,
                                                  identifier: identifier)
    return httpClient.sendDecodableRequest(request)
  }

  open func delete(_ path: String,
                   params: [(String, String?)]? = nil,
                   identifier: String? = nil) throws -> Promise<(HTTPURLResponse, Data?)> {
    let request = try HTTPRequest.generateRequest(config.host,
                                                  path: path,
                                                  params: params,
                                                  method: .delete,
                                                  identifier: identifier)
    return httpClient.send(request)
  }
}
