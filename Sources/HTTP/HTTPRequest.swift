//
//  HTTPRequest.swift
//  HTTP
//

import Foundation
import PromiseKit

// MARK: Requestable

public protocol Requestable {
    var request: URLRequest { get set }
    var identifier: String { get }
}

// MARK: URLRequest - Requestable

extension URLRequest: Requestable {
    public var request: URLRequest {
        get {
            return self
        }
        set {
            self = newValue
        }
    }

    public var identifier: String { return request.url!.absoluteString }
}

public class IdentifiedURLRequest: Requestable {
    public var request: URLRequest
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
        case failedToCreateRequest
    }

    public enum Method: String {
        case get = "GET"
        case put = "PUT"
        case post = "POST"
        case delete = "DELETE"
    }

    public static func generateRequest<T: Encodable>(
        _ host: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        payload: T,
        method: Method = .post,
        identifier: String? = nil
    ) throws -> Requestable {
        guard method != .get else { throw HTTPRequestError.getRequestCannotHaveBody }
        guard var urlComponents = URLComponents(string: host) else { throw HTTPRequestError.failedToCreateURL(host) }
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else { throw HTTPRequestError.failedToCreateURL("\(urlComponents)") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        do {
            request.httpBody = try encode(payload)
        } catch {
            throw HTTPRequestError.encodingFailed(payload)
        }
        return resolveRequestable(request, identifier: identifier)
    }

    public static func generateRequest(
        _ host: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: Method = .get,
        identifier: String? = nil
    ) throws -> Requestable {
        guard var urlComponents = URLComponents(string: host) else { throw HTTPRequestError.failedToCreateURL(host) }
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else { throw HTTPRequestError.failedToCreateURL("\(urlComponents)") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return resolveRequestable(request, identifier: identifier)
    }

    public static func generateRequest(
        _ urlString: String,
        queryItems: [URLQueryItem]? = nil,
        method: Method = .get,
        identifier: String? = nil
    ) throws -> Requestable {
        guard var urlComponents = URLComponents(string: urlString) else { throw HTTPRequestError.failedToCreateURL(urlString) }
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else { throw HTTPRequestError.failedToCreateURL("\(urlComponents)") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return resolveRequestable(request, identifier: identifier)
    }

    public static
    func generateRequest<T: Encodable>(
        _ urlString: String,
        queryItems: [URLQueryItem]? = nil,
        method: Method = .post,
        payload: T,
        identifier: String? = nil
    ) throws -> Requestable {
        guard method != .get else {
            throw HTTPRequestError.getRequestCannotHaveBody
        }

        var components = URLComponents(string: urlString)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw HTTPRequestError.failedToCreateURL(urlString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        do {
            request.httpBody = try encode(payload)
        } catch {
            throw HTTPRequestError.encodingFailed(payload)
        }
        return resolveRequestable(request, identifier: identifier)
    }

    private static func encode<T: Encodable>(_ payload: T) throws -> Data {
        let encoder = JSONEncoder()
        if let reqPay = payload as? RequestPayload {
            encoder.keyEncodingStrategy = type(of: reqPay).keyEncodingStrategy
        }
        return try encoder.encode(payload)
    }
}

private extension HTTPRequest {
    static func resolveRequestable(
        _ request: URLRequest,
        identifier: String?
    ) -> Requestable {
        if let identifier = identifier {
            return IdentifiedURLRequest(request: request, identifier: identifier)
        }
        return request
    }
}
