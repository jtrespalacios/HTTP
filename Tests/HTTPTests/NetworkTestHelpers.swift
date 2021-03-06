import HTTP
import XCTest

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
        return TestCodable(
            name: "King of Symmetry",
            age: years
        )
    }

    static func testData() -> Data {
        try! JSONEncoder().encode(testSubject())
    }
}

struct FailingEncoding: Codable {
    enum FailingEncodingError: Error {
        case knownError
    }

    func encode(to _: Encoder) throws {
        throw FailingEncodingError.knownError
    }
}

func == (lhs: TestCodable, rhs: TestCodable) -> Bool {
    lhs.name == rhs.name && lhs.age == rhs.age
}

class HTTPClientTestCase: XCTestCase {
    var sessionMock: URLSessionProtocolMock!
    var client: APIClient!
    var httpClient: HTTPClient! { client.httpClient }
    typealias Headers = [(key: String, value: String)]
    struct TestAPIConfig: APIClientConfig, Equatable {
        static func == (lhs: HTTPClientTestCase.TestAPIConfig, rhs: HTTPClientTestCase.TestAPIConfig) -> Bool {
            func compareHeaders(_ lhs: Headers, _ rhs: Headers) -> Bool {
                let sl = lhs.sorted(by: { $0.key < $1.key })
                let rl = rhs.sorted(by: { $0.key < $1.key })
                var result = true
                for (index, value) in sl.enumerated() {
                    let rv = rl[index]
                    result = value.key == rv.key && value.value == rv.value
                    if !result {
                        break
                    }
                }
                return result
            }
            return lhs.host == rhs.host &&
                lhs.headers.count == rhs.headers.count &&
                compareHeaders(lhs.headers, rhs.headers)
        }

        let host: String
        let headers: [(key: String, value: String)] = []

        init(host: String = Constants.testHost) {
            self.host = host
        }
    }

    enum Constants {
        static let testHost = "http://example.com"
        static let badHost = "////!@#$^#@$"
        static let path = "/search"
        static let testUrl = URL(string: testHost)!
        static let queryItems = [URLQueryItem(name: "jared", value: "kushner"), URLQueryItem(name: "donald", value: "trump")]
    }

    func resolveRun(
        data: Data? = "".data(using: .utf8),
        response: URLResponse? = HTTPURLResponse(url: URL(string: Constants.testHost)!, statusCode: 200, httpVersion: nil, headerFields: nil),
        error: Error? = nil
    ) {
        sessionMock.dataTaskReceivedArguments!.completionHandler(data, response, error)
    }

    func response(statusCode: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: Constants.testHost)!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
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
        client = try! APIClient(config: TestAPIConfig(), session: sessionMock)
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
