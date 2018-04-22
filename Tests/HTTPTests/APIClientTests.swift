//
//  APIClientTests.swift
//  _Tests
//
//  Created by Jeff Trespalacios on 11/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import HTTP

class APIClientTests: HTTPClientTestCase {
    func testPut() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.put(Constants.path, payload: TestCodable.testSubject(), queryItems: Constants.queryItems).then { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
                XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testPost() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.post(Constants.path, payload: TestCodable.testSubject(), queryItems: Constants.queryItems).then { (result: TestCodable) in
            self.validateResult(result, e: e)
            }.catch { _ in
                XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testDelete() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.delete(Constants.path, queryItems: Constants.queryItems).then { (response: HTTPURLResponse, _: Data?) in
            self.validateResult(response, statusCode: 200, e: e)
        }.catch { _ in
                XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testRequestableRoute() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.send(TestSimpleRoute()).then { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
                XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testRequestableUploadRoute() {
        let e = expectation(description: "Should resolve with a test codable")
        try! client.send(TestUploadRoute()).then { (result: TestCodable) in
            self.validateResult(result, e: e)
            }.catch { _ in
                XCTFail("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }
}

struct TestSimpleRoute: RequestableRoute {
    var path: String { return "/search" }
    var method: HTTPRequest.Method { return .get }
    var queryItems: [URLQueryItem]? { return nil }
    var identifier: String? { return nil }
}

struct TestUploadRoute: RequestableUploadRoute {
    typealias Payload = TestCodable
    var path: String { return "/search" }
    var method: HTTPRequest.Method { return .post }
    var queryItems: [URLQueryItem]? { return nil }
    var identifier: String? { return nil }
    var payload: Payload { return TestCodable.testSubject() }
}
