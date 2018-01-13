//
//  HTTPRequest.swift
//  HTTP
//

import Foundation
import PromiseKit

// MARK: Requestable
public protocol Requestable {
    var request: URLRequest { get }
    var identifier: String { get }
}

// MARK: URLRequest - Requestable
extension URLRequest: Requestable {
    public var request: URLRequest { return self }
    public var identifier: String { return request.url!.absoluteString }
}

public class IdentifiedURLRequest: Requestable {
    public let request: URLRequest
    public let identifier: String

    init(request: URLRequest, identifier: String) {
        self.request = request
        self.identifier = identifier
    }
}

public class HTTPRequest {
    public enum HTTPRequestError: Error {
        case getRequestCannotHaveBody
        case failedToCreateURL(String)
        case encodingFailed(Encodable)
    }

    public enum Method: String {
        case get = "GET"
        case put = "PUT"
        case post = "POST"
        case delete = "DELETE"
    }

    public static func generateRequest<T: Encodable>(_ host: String,
                                                     path: String,
                                                     payload: T,
                                                     queryItems: [URLQueryItem]? = nil,
                                                     method: Method = .post,
                                                     identifier: String? = nil) throws -> Requestable {
        guard method != .get else { throw HTTPRequestError.getRequestCannotHaveBody }
        guard var urlComponents = URLComponents(string: host) else { throw HTTPRequestError.failedToCreateURL(host) }
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else { throw HTTPRequestError.failedToCreateURL("\(urlComponents)") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            throw HTTPRequestError.encodingFailed(payload)
        }
        return resolveRequestable(request, identifier: identifier)
    }

    public static func generateRequest(_ host: String,
                                       path: String,
                                       queryItems: [URLQueryItem]? = nil,
                                       method: Method = .get,
                                       identifier: String? = nil) throws -> Requestable {
        guard var urlComponents = URLComponents(string: host) else { throw HTTPRequestError.failedToCreateURL(host) }
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else { throw HTTPRequestError.failedToCreateURL("\(urlComponents)") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return resolveRequestable(request, identifier: identifier)
    }

    public static func generateRequest<T: Encodable>(_ url: URL,
                                                     payload: T,
                                                     method: Method = .post,
                                                     identifier: String? = nil) throws -> Requestable {
        guard method != .get else { throw HTTPRequestError.getRequestCannotHaveBody }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            throw HTTPRequestError.encodingFailed(payload)
        }
        return resolveRequestable(request, identifier: identifier)
    }

    public static func generateRequest(_ url: URL,
                                       method: Method = .get,
                                       identifier: String? = nil) -> Requestable {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return resolveRequestable(request, identifier: identifier)
    }
}

private extension HTTPRequest {
    static func resolveRequestable(_ request: URLRequest, identifier: String?) -> Requestable {
        if let identifier = identifier {
            return IdentifiedURLRequest(request: request, identifier: identifier)
        }
        return request
    }
}
