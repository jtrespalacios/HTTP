@testable import HTTP
import XCTest

class APIClientTests: HTTPClientTestCase {
    func testPut() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.put(
            Constants.path,
            payload: TestCodable.testSubject(),
            queryItems: Constants.queryItems
        ).done { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
            XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testPost() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.post(
            Constants.path,
            payload: TestCodable.testSubject(),
            queryItems: Constants.queryItems
        ).done { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
            XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testDelete() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.delete(
            Constants.path,
            queryItems: Constants.queryItems
        ).done { (response: HTTPURLResponse, _: Data?) in
            self.validateResult(response, statusCode: 200, e: e)
        }.catch { _ in
            XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testRequestableRoute() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.send(TestSimpleRoute()).done { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
            XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testRequestableUploadRoute() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.send(TestUploadRoute()).done { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
            XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }
}

struct TestSimpleRoute: RequestableRoute {
    var path: String { "/search" }
    var method: HTTPRequest.Method { .get }
    var queryItems: [URLQueryItem]? { nil }
    var identifier: String? { nil }
}

struct TestUploadRoute: RequestableUploadRoute {
    typealias Payload = TestCodable
    var path: String { "/search" }
    var method: HTTPRequest.Method { .post }
    var queryItems: [URLQueryItem]? { nil }
    var identifier: String? { nil }
    var payload: Payload { TestCodable.testSubject() }
}
