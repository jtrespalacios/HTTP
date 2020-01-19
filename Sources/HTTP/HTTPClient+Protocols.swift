//
//  HTTPClient+Protocols.swift
//  HTTP
//

import Foundation

public protocol URLSessionDownloadTaskProtocol {
    func resume()
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

public protocol URLSessionProtocol {
    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTaskProtocol
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}
extension URLSessionDownloadTask: URLSessionDownloadTaskProtocol {}

extension URLSession: URLSessionProtocol {
    public func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTaskProtocol {
        let task: URLSessionDownloadTask = downloadTask(with: url, completionHandler: completionHandler)
        return task as URLSessionDownloadTaskProtocol
    }

    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let task: URLSessionDataTask = dataTask(with: request, completionHandler: completionHandler)
        return task as URLSessionDataTaskProtocol
    }
}
