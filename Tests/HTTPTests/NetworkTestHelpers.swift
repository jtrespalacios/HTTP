//
//  NetworkTestHelpers.swift
//  HTTP_Example
//
//  Created by Jeff Trespalacios on 11/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import HTTP

class URLSessionTasklMock: URLSessionDownloadTaskProtocol, URLSessionDataTaskProtocol {
    var resumeCalled = false
    func resume() {
        resumeCalled = true
    }
}

class URLSessionProtocolMock: URLSessionProtocol {
    // MARK: - downloadTask
    var downloadTaskCalled = false
    var downloadTaskReceivedArguments: (url: URL, completionHandler: (URL?, URLResponse?, Error?) -> Void)?
    var downloadTaskReturnValue: URLSessionDownloadTaskProtocol = URLSessionTasklMock()

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTaskProtocol {
        downloadTaskCalled = true
        downloadTaskReceivedArguments = (url: url, completionHandler: completionHandler)
        return downloadTaskReturnValue
    }

    // MARK: - dataTask
    var dataTaskCalled = false
    var dataTaskReceivedArguments: (request: URLRequest, completionHandler: (Data?, URLResponse?, Error?) -> Swift.Void)?
    var dataTaskReturnValue: URLSessionDataTaskProtocol = URLSessionTasklMock()

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol {
        dataTaskCalled = true
        dataTaskReceivedArguments = (request: request, completionHandler: completionHandler)
        return dataTaskReturnValue
    }
}

struct TestCodable: Codable, Equatable {
    let name: String
    let age: Int

    static func testSubject() -> TestCodable {
        let birthDate = Calendar.autoupdatingCurrent.date(from: DateComponents(year: 1967, month: 2, day: 27))!
        let years = Calendar.autoupdatingCurrent.dateComponents([.year], from: birthDate, to: Date()).year!
        return TestCodable(name: "King of Symmetry",
                           age: years)
    }

    static func testData() -> Data {
        return try! JSONEncoder().encode(testSubject())
    }
}

struct FailingEncoding: Codable {
    enum FailingEncodingError: Error {
        case knownError
    }

    func encode(to: Encoder) throws {
        throw FailingEncodingError.knownError
    }
}

func ==(lhs: TestCodable, rhs: TestCodable) -> Bool {
    return lhs.name == rhs.name && lhs.age == rhs.age
}

class HTTPClientTestCase: XCTestCase {
    var sessionMock: URLSessionProtocolMock!
    var client: APIClient!
    var httpClient: HTTPClient! { return client.httpClient }
    let testURL = URL(string: Constants.testHost)!

    enum Constants {
        static let testHost = "http://example.com"
        static let badHost = "////!@#$^#@$"
        static let path = "/search"
        static let queryItems = [URLQueryItem(name: "jared", value: "kushner"), URLQueryItem(name: "donald", value: "trump")]
    }

    func resolveRun(data: Data? = "".data(using: .utf8),
                    response: URLResponse? = HTTPURLResponse(url: URL(string: Constants.testHost)!, statusCode: 200, httpVersion: nil, headerFields: nil),
                    error: Error? = nil) {
        sessionMock.dataTaskReceivedArguments!.completionHandler(data, response, error)
    }

    func response(statusCode: Int = 200) -> HTTPURLResponse {
        return HTTPURLResponse(url: URL(string: Constants.testHost)!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    func validateResult(_ result: TestCodable, e: XCTestExpectation) {
        XCTAssertTrue(result == TestCodable.testSubject())
        e.fulfill()
    }

    func validateResult(_ httpResponse: HTTPURLResponse, statusCode: Int, e: XCTestExpectation) {
        XCTAssertEqual(httpResponse.statusCode, statusCode)
        e.fulfill()
    }

//    func validateResult(_ image: UIImage, data: Data, e: XCTestExpectation) {
//        XCTAssertEqual(UIImagePNGRepresentation(image), data)
//        e.fulfill()
//    }

    override func setUp() {
        super.setUp()
        sessionMock = URLSessionProtocolMock()
        client = try! APIClient(host: Constants.testHost, session: sessionMock)
    }
}

class RejectingAPIClient: APIClient {
    static let badIdentifier = "http://example.com"
    enum RejectingAPIClientError: Error {
        case expectedError
    }

    override func willSend(request: inout Requestable) throws {
        debugPrint("\(request)")
        if request.identifier == RejectingAPIClient.badIdentifier {
            throw RejectingAPIClientError.expectedError
        }
    }
}
