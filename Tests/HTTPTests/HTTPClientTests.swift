//
//  HTTPClientTests.swift
//  HTTP_Tests
//
//  Created by Jeff Trespalacios on 11/20/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

@testable import HTTP
import PromiseKit
import XCTest

class HTTPClientTests: HTTPClientTestCase {
    func testSessionConfigInit() {
        let anotherClient = try! APIClient(config: TestAPIConfig(), session: URLSession(configuration: .default))
        XCTAssertEqual(anotherClient.config as! TestAPIConfig, TestAPIConfig())
    }

    func testSessionConfigInitFail() {
        XCTAssertThrowsError(try APIClient(config: TestAPIConfig(host: Constants.badHost), sessionConfig: .default))
    }

    func testBadAPIClientHost() {
        XCTAssertThrowsError(try APIClient(
            config: TestAPIConfig(host: Constants.badHost),
            session: sessionMock
        ))
    }

    func testRejectedAPIRequest() {
        let e = expectation(description: "Testing a rejected request")
        let anotherClient = try! RejectingAPIClient(
            config: TestAPIConfig(),
            session: sessionMock
        )
        try! anotherClient.get("").done { (_: String) in
            XCTFail("This should not resolve to a value")
        }.catch { error in
            XCTAssertTrue(error is RejectingAPIClient.RejectingAPIClientError)
            e.fulfill()
        }
        wait(for: [e], timeout: 0.1)
    }

    func testBadRequestErrors() {
        var expectations = [XCTestExpectation]()
        for x in 400 ..< 500 {
            let e = expectation(description: "Testing response code \(x)")
            try! client.get("").done { (_: String) in
                XCTFail("This should not resolve to a value")
            }.catch { error in
                XCTAssertTrue(error is HTTPClient.HTTPClientError)
                e.fulfill()
            }
            resolveRun(response: response(statusCode: x), error: nil)
            expectations.append(e)
        }
        wait(for: expectations, timeout: 0.1)
    }

    func testServerErrors() {
        var expectations = [XCTestExpectation]()
        for x in 500 ..< 600 {
            let e = expectation(description: "Testing response code \(x)")
            try! client.get("").done { (_: String) in
                XCTFail("This should not resolve to a value")
            }.catch { error in
                XCTAssertTrue(error is HTTPClient.HTTPClientError)
                e.fulfill()
            }
            expectations.append(e)
            resolveRun(response: response(statusCode: x))
        }
        wait(for: expectations, timeout: 0.1)
    }

    func testURLRequestRequestableConformance() {
        let request = URLRequest(url: URL(string: Constants.testHost)!)
        XCTAssertEqual(request.identifier, Constants.testHost)
    }

    func testGenerateGetRequestWithBody() {
        XCTAssertThrowsError(try HTTPRequest.generateRequest(Constants.testHost, path: "", payload: TestCodable.testSubject(), method: .get))
    }

    func testGenerateRequestBadHost() {
        XCTAssertThrowsError(
            try HTTPRequest.generateRequest(Constants.badHost, path: "")
        )
    }

    func testGenerateRequestWithPath() {
        let request = try! HTTPRequest.generateRequest(Constants.testHost, path: "/search")
        XCTAssertEqual(request.identifier, "\(Constants.testHost)/search")
    }

    func testGenerateRequestSimpleRequest() {
        let requestable = try! HTTPRequest.generateRequest(Constants.testHost)
        XCTAssertEqual(requestable.identifier, Constants.testHost)
        XCTAssertEqual(requestable.request.httpMethod!, HTTPRequest.Method.get.rawValue)
    }

    func testGenerateRequestSimpleRequestFailure() {
        XCTAssertThrowsError(try HTTPRequest.generateRequest(Constants.testHost, path: "ÔÓØˆ¨˝Øˆ¨˝˝ÎÁˇ‰"))
    }

    func testGenerateRequestEncodablePayload() {
        XCTAssertThrowsError(try HTTPRequest.generateRequest(Constants.testHost, path: "ÔÓØˆ¨˝Øˆ¨˝˝ÎÁˇ‰", payload: FailingEncoding()))
        XCTAssertThrowsError(try HTTPRequest.generateRequest(Constants.testHost, path: "", payload: FailingEncoding()))
        XCTAssertThrowsError(try HTTPRequest.generateRequest(Constants.badHost, path: "", payload: FailingEncoding()))
    }

    func testGenerateRequestEncodableURLRequest() {
        XCTAssertThrowsError(try HTTPRequest.generateRequest(Constants.testHost, payload: FailingEncoding()))
        XCTAssertThrowsError(try HTTPRequest.generateRequest(Constants.testHost, method: .get, payload: FailingEncoding()))
    }

    func testRequestWithSpecifiedIdentifier() {
        let requestable = try! HTTPRequest.generateRequest(Constants.testHost,
                                                           path: "/",
                                                           queryItems: nil,
                                                           method: .get,
                                                           identifier: "Getting the test host")
        XCTAssertEqual("Getting the test host", requestable.identifier)
    }

    func testGet() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.get(
            url: Constants.testHost,
            queryItems: nil
        )
        .done { (httpResponse: HTTPURLResponse, _: Data?) in
            self.validateResult(httpResponse, statusCode: 200, e: e)
        }
        resolveRun()
        wait(for: [e], timeout: 0.1)
    }

    func testPut() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.put(
            Constants.testHost,
            queryItems: nil,
            payload: TestCodable.testSubject()
        ).done { (httpResponse: HTTPURLResponse, _: Data?) in
            self.validateResult(httpResponse, statusCode: 200, e: e)
        }
        resolveRun()
        wait(for: [e], timeout: 0.1)
    }

    func testPost() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.post(
            Constants.testHost,
            queryItems: nil,
            payload: TestCodable.testSubject()
        ).done { (httpResponse: HTTPURLResponse, _: Data?) in
            self.validateResult(httpResponse, statusCode: 200, e: e)
        }
        resolveRun()
        wait(for: [e], timeout: 0.1)
    }

    func testDelete() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.delete(Constants.testHost).done { (httpResponse: HTTPURLResponse, _: Data?) in
            self.validateResult(httpResponse, statusCode: 200, e: e)
        }
        resolveRun()
        wait(for: [e], timeout: 0.1)
    }

    func testGetDecodable() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.get(Constants.testHost).done { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
            fatalError("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testGetDecodableFail() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.sendDecodableRequest(URLRequest(url: URL(string: Constants.testHost)!)).done { (_: FailingEncoding) in
            XCTFail("This should not succeed")
        }.catch { error in
            XCTAssertTrue(error is HTTPClient.HTTPClientError)
            e.fulfill()
        }
        resolveRun()
        wait(for: [e], timeout: 0.1)
    }

    func testGetDecodableFailNoData() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.sendDecodableRequest(URLRequest(url: URL(string: Constants.testHost)!)).done { (_: FailingEncoding) in
            XCTFail("This should not succeed")
        }.catch { error in
            XCTAssertTrue(error is HTTPClient.HTTPClientError)
            e.fulfill()
        }
        resolveRun(data: nil)
        wait(for: [e], timeout: 0.1)
    }

    func testGenerateRequestURLAndPayload() {
        let requestable = try! HTTPRequest.generateRequest(Constants.testHost, method: .put, payload: TestCodable.testSubject())
        XCTAssertEqual(requestable.request.httpBody!, TestCodable.testData())
        XCTAssertEqual(requestable.identifier, Constants.testHost)
        XCTAssertEqual(requestable.request.httpMethod!, HTTPRequest.Method.put.rawValue)
    }

    func testGenerateRequestURLAndMethod() {
        let requestable = try! HTTPRequest.generateRequest(Constants.testHost, method: .get)
        XCTAssertEqual(requestable.identifier, Constants.testHost)
        XCTAssertEqual(requestable.request.httpMethod!, HTTPRequest.Method.get.rawValue)
    }

    func testPutDecodable() {
        let e = expectation(description: "Should resolve with a http response")
        _ = httpClient.put(Constants.testHost, payload: TestCodable.testSubject()).done { (result: TestCodable) in
            self.validateResult(result, e: e)
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testPostDecodable() {
        let e = expectation(description: "Should resolve with a http response")
        try! httpClient.post(Constants.testHost, payload: TestCodable.testSubject()).done { (result: TestCodable) in
            self.validateResult(result, e: e)
        }.catch { _ in
            fatalError("This should not fail")
        }
        resolveRun(data: TestCodable.testData())
        wait(for: [e], timeout: 0.1)
    }

    func testPutFailure() {
        let e = expectation(description: "Should resolve with a http response")
        httpClient.put(
            Constants.testHost,
            queryItems: nil,
            payload: TestCodable.testSubject()
        ).done { (_: HTTPURLResponse, _: Data?) in
            XCTFail("This should not resolve")
        }.catch { error in
            XCTAssertTrue(error is HTTPClient.HTTPClientError)
            e.fulfill()
        }
        resolveRun(response: response(statusCode: 500))
        wait(for: [e], timeout: 0.1)
    }

    func testPostFailure() {
        let e = expectation(description: "Should resolve with a http response")
        httpClient.post(
            Constants.testHost,
            queryItems: nil,
            payload: TestCodable.testSubject()
        ).done { (_: HTTPURLResponse, _: Data?) in
            XCTFail("This should not resolve")
        }.catch { error in
            XCTAssertTrue(error is HTTPClient.HTTPClientError)
            e.fulfill()
        }
        resolveRun(response: response(statusCode: 500))
        wait(for: [e], timeout: 0.1)
    }

    func testDeleteFailure() {
        let e = expectation(description: "Should resolve with a http response")
        httpClient.delete(Constants.testHost).done { (_: HTTPURLResponse, _: Data?) in
            XCTFail("This should not resolve")
        }.catch { error in
            XCTAssertTrue(error is HTTPClient.HTTPClientError)
            e.fulfill()
        }
        resolveRun(response: response(statusCode: 500))
        wait(for: [e], timeout: 0.1)
    }

//    func testGetImage() {
//        let testImage = UIImage(named: "test.jpg")!
//        let testData = UIImagePNGRepresentation(testImage)!
//        let e = expectation(description: "Should resolve with a http response")
//        httpClient.get(testURL).then { (image: UIImage) in
//            self.validateResult(image, data: testData, e: e)
//            }.catch { error in
//                XCTFail("This should not fail")
//        }
//        resolveRun(data: testData)
//        wait(for: [e], timeout: 0.1)
//    }
//
//    func testGetImageFail() {
//        let e = expectation(description: "Should resolve with a http response")
//        httpClient.get(testURL).then { (image: UIImage) in
//            XCTFail("This should not resolve")
//            }.catch { error in
//                XCTAssertTrue(error is HTTPClient.HTTPClientError)
//                e.fulfill()
//        }
//        resolveRun()
//        wait(for: [e], timeout: 0.1)
//    }
//
//    func testGetImageNoDataFail() {
//        let e = expectation(description: "Should resolve with a http response")
//        httpClient.get(testURL).then { (image: UIImage) in
//            XCTFail("This should not resolve")
//            }.catch { error in
//                XCTAssertTrue(error is HTTPClient.HTTPClientError)
//                e.fulfill()
//        }
//        resolveRun(data: nil)
//        wait(for: [e], timeout: 0.1)
//    }

    func testRequestFailsWithError() {
        enum FakeError: Error {
            case knownError
        }
        let e = expectation(description: "Should resolve with a http response")
        httpClient.send(URLRequest(url: Constants.testUrl)).done { (_: HTTPURLResponse, _: Data?) in
            XCTFail("This should not resolve")
        }.catch { error in
            XCTAssertTrue(error is FakeError)
            e.fulfill()
        }
        resolveRun(error: FakeError.knownError)
        wait(for: [e], timeout: 0.1)
    }

    func testBadResponse() {
        let e = expectation(description: "Testing getting bad response")
        httpClient.get(url: Constants.testHost, queryItems: nil).done { (_: HTTPURLResponse, _: Data?) in
            XCTFail("This should not resolve")
        }.catch { error in
            XCTAssertTrue(error is HTTPClient.HTTPClientError)
            e.fulfill()
        }
        resolveRun(response: URLResponse())
        wait(for: [e], timeout: 0.1)
    }
}
