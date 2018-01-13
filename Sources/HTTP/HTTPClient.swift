//
//  HTTPClient.swift
//  HTTP
//


import Foundation
import PromiseKit

public protocol HTTP {
    var session: URLSessionProtocol { get }
    func send(_ request: Requestable) -> Promise<(HTTPURLResponse, Data?)>
    func get(url: URL) -> Promise<(HTTPURLResponse, Data?)>
    func get<T: Decodable>(_ url: URL) -> Promise<T>
    func post<T: Encodable>(_ url: URL, payload: T) -> Promise<(HTTPURLResponse, Data?)>
    func post<T: Encodable, U: Decodable>(_ url: URL, payload: T) throws -> Promise<U>
    func put<T: Encodable>(_ url: URL, payload: T) -> Promise<(HTTPURLResponse, Data?)>
    func put<T: Encodable, U: Decodable>(_ url: URL, payload: T) throws -> Promise<U>
    func delete(_ url: URL) -> Promise<(HTTPURLResponse, Data?)>
}

public protocol HTTPClientDelegate: class {
    func willSend(request: inout Requestable) throws
}

public class HTTPClient: HTTP {
    public static var defaultClient: HTTPClient = {
        let queue = OperationQueue()
        let defaultSession: URLSessionProtocol = URLSession(configuration: .default, delegate: nil, delegateQueue: queue)
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

    public init(sessionConfig: URLSessionConfiguration = .default, queue: OperationQueue = OperationQueue()) {
        session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: queue)
    }

    public func send(_ requestable: Requestable) -> Promise<(HTTPURLResponse, Data?)> {
        return Promise<(HTTPURLResponse, Data?)> { fulfill, reject in
            var requestable = requestable
            do {
                try delegate?.willSend(request: &requestable)
            } catch {
                reject(error)
                return
            }

            session.dataTask(with: requestable.request) { [weak self] (data, response, error) in
                guard error == nil else { reject(error!); return }
                guard let httpResponse = response as? HTTPURLResponse else {
                    reject(HTTPClientError.unexpectedResponse(data, response))
                    return
                }
                do {
                    try self?.responseHasError(httpResponse, data: data)
                } catch {
                    reject(error)
                }
                fulfill((httpResponse, data))
                }.resume()
        }
    }

    public func get(url: URL) -> Promise<(HTTPURLResponse, Data?)> {
        return send(HTTPRequest.generateRequest(url))
    }

    public func post<T: Encodable>(_ url: URL, payload: T) -> Promise<(HTTPURLResponse, Data?)> {
        return Promise<(HTTPURLResponse, Data?)> { fulfill, reject in
            let request = try HTTPRequest.generateRequest(url, payload: payload)
            send(request).then { result in
                fulfill(result)
            }.catch { error in
                reject(error)
            }
        }
    }

    public func put<T: Encodable>(_ url: URL, payload: T) -> Promise<(HTTPURLResponse, Data?)> {
        return Promise<(HTTPURLResponse, Data?)> { fulfill, reject in
            let request = try HTTPRequest.generateRequest(url, payload: payload, method: .put)
            send(request).then { result in
                fulfill(result)
            }.catch { error in
                reject(error)
            }
        }
    }

    public func delete(_ url: URL) -> Promise<(HTTPURLResponse, Data?)> {
        return Promise<(HTTPURLResponse, Data?)> { fulfill, reject in
            send(HTTPRequest.generateRequest(url, method: .delete)).then { result in
                fulfill(result)
            }.catch { error in
                reject(error)
            }
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

    public func get<T: Decodable>(_ url: URL) -> Promise<T> {
        return sendDecodableRequest(HTTPRequest.generateRequest(url))
    }

    public func post<T: Encodable, U: Decodable>(_ url: URL, payload: T) throws -> Promise<U> {
        let request = try HTTPRequest.generateRequest(url, payload: payload, method: .post)
        return sendDecodableRequest(request)
    }

    public func put<T: Encodable, U: Decodable>(_ url: URL, payload: T) throws -> Promise<U> {
        let request = try HTTPRequest.generateRequest(url, payload: payload, method: .put)
        return sendDecodableRequest(request)
    }

    public func sendDecodableRequest<T: Decodable>(_ requestable: Requestable) -> Promise<T> {
        return send(requestable).then { (response: HTTPURLResponse, data: Data?) in
            return Promise<T> { fulfill, reject in
                guard let data = data else {
                    reject(HTTPClientError.unexpectedResponse(nil, response))
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let result: T = try decoder.decode(T.self, from: data)
                    fulfill(result)
                } catch {
                    reject(HTTPClientError.decodingFailed(T.self, data))
                }
            }
        }
    }

    open func responseHasError(_ response: HTTPURLResponse, data: Data?) throws {
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
