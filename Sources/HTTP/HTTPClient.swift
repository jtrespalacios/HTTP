//
//  HTTPClient.swift
//  HTTP
//

import Foundation
import PromiseKit

public protocol HTTPClientDelegate: class {
    func willSend(request: inout Requestable) throws
}

public class HTTPClient: HTTPRequester {
    public static var defaultClient: HTTPClient = {
        let defaultSession: URLSessionProtocol = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        return HTTPClient(session: defaultSession)
    }()

    public enum HTTPClientError: Error {
        case decodingFailed(Decodable.Type, Data)
        case unexpectedResponse(Data?, URLResponse?)
        case failedToMakeImage(Data?)
        case badRequest(Int)
        case serverError(Int)
    }

    public var session: URLSessionProtocol
    public weak var delegate: HTTPClientDelegate?

    public init(session: URLSessionProtocol) {
        self.session = session
    }

    public init(sessionConfig: URLSessionConfiguration = .default,
                queue: OperationQueue = OperationQueue()) {
        session = URLSession(configuration: sessionConfig,
                             delegate: nil,
                             delegateQueue: queue)
    }

    public func send(_ requestable: Requestable) -> Promise<(HTTPURLResponse, Data?)> {
        return Promise<(HTTPURLResponse, Data?)> { seal in
            var requestable = requestable
            do {
                try delegate?.willSend(request: &requestable)
            } catch {
                seal.reject(error)
            }

            session.dataTask(with: requestable.request) { [weak self] data, response, error in
                guard error == nil else { seal.reject(error!); return }
                guard let httpResponse = response as? HTTPURLResponse else {
                    seal.reject(HTTPClientError.unexpectedResponse(data, response))
                    return
                }
                do {
                    try self?.responseHasError(httpResponse, data: data)
                } catch {
                    seal.reject(error)
                }
                seal.fulfill((httpResponse, data))
            }.resume()
        }
    }

    public func get(url: String, queryItems: [URLQueryItem]?) -> Promise<(HTTPURLResponse, Data?)> {
        do {
            return try send(HTTPRequest.generateRequest(url, queryItems: queryItems, method: .get))
        } catch {
            return Promise(error: error)
        }
    }

    public func post<T: Encodable>(_ url: String, queryItems: [URLQueryItem]?, payload: T) -> Promise<(HTTPURLResponse, Data?)> {
        do {
            let request = try HTTPRequest.generateRequest(url,
                                                          queryItems: queryItems,
                                                          payload: payload)
            return send(request)
        } catch {
            return Promise(error: error)
        }
    }

    public func put<T: Encodable>(_ url: String, queryItems: [URLQueryItem]?, payload: T) -> Promise<(HTTPURLResponse, Data?)> {
        do {
            let request = try HTTPRequest.generateRequest(url,
                                                          queryItems: queryItems,
                                                          method: .put,
                                                          payload: payload)
            return send(request)
        } catch {
            return Promise(error: error)
        }
    }

    public func delete(
        _ url: String,
        queryItems: [URLQueryItem]? = nil
    ) -> Promise<(HTTPURLResponse, Data?)> {
        do {
            return try send(HTTPRequest.generateRequest(
                url,
                queryItems: queryItems,
                method: .delete
            ))
        } catch {
            return Promise(error: error)
        }
    }

    //    public func get(_ url: URL) -> Promise<UIImage> {
    //        return send(HTTPRequest.generateRequest(url)).then { _, data in
    //            return Promise<UIImage> { fulfill, reject in
    //                guard let data = data else {
    //                    reject(HTTPClientError.failedToMakeImage(nil))
    //                    return
    //                }
    //                if let image = UIImage(data: data) {
    //                    fulfill(image)
    //                } else {
    //                    reject(HTTPClientError.failedToMakeImage(data))
    //                }
    //            }
    //        }
    //    }

    public func get<T: Decodable>(
        _ url: String,
        queryItems: [URLQueryItem]? = nil
    ) -> Promise<T> {
        do {
            let request = try HTTPRequest.generateRequest(url, queryItems: queryItems, method: .get, identifier: nil)
            return sendDecodableRequest(request)
        } catch {
            return Promise(error: error)
        }
    }

    public func post<T: Encodable, U: Decodable>(
        _ url: String,
        queryItems: [URLQueryItem]? = nil,
        payload: T
    ) throws -> Promise<U> {
        let request = try HTTPRequest.generateRequest(url,
                                                      queryItems: queryItems,
                                                      method: .post,
                                                      payload: payload)
        return sendDecodableRequest(request)
    }

    public func put<T: Encodable, U: Decodable>(
        _ url: String,
        queryItems: [URLQueryItem]? = nil,
        payload: T
    ) -> Promise<U> {
        do {
            let request = try HTTPRequest.generateRequest(url, queryItems: queryItems, method: .put, payload: payload)
            return sendDecodableRequest(request)
        } catch {
            return Promise(error: error)
        }
    }

    public func sendDecodableRequest<T: Decodable>(_ requestable: Requestable) -> Promise<T> {
        return send(requestable).then { (response: HTTPURLResponse, data: Data?) in
            Promise<T> { seal in
                guard let data = data else {
                    seal.reject(HTTPClientError.unexpectedResponse(nil, response))
                    return
                }
                do {
                    let result: T = try JSONDecoder().decode(T.self, from: data)
                    seal.fulfill(result)
                } catch {
                    seal.reject(HTTPClientError.decodingFailed(T.self, data))
                }
            }
        }
    }

    public func sendDecodableRequest<T: ResponsePayload>(_ requestable: Requestable) -> Promise<T> {
        return send(requestable).then { (response: HTTPURLResponse, data: Data?) in
            Promise<T> { seal in
                guard let data = data else {
                    seal.reject(HTTPClientError.unexpectedResponse(nil, response))
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = T.self.keyDecodingStrategy
                    let result: T = try decoder.decode(T.self, from: data)
                    seal.fulfill(result)
                } catch {
                    seal.reject(HTTPClientError.decodingFailed(T.self, data))
                }
            }
        }
    }

    open func responseHasError(_ response: HTTPURLResponse, data _: Data?) throws {
        switch response.statusCode {
        case 400 ..< 500:
            throw HTTPClientError.badRequest(response.statusCode)
        case 500 ..< 600:
            throw HTTPClientError.serverError(response.statusCode)
        default:
            break
        }
    }
}
