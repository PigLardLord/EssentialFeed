//
//  URLSessionHttpClientTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 18/10/23.
//

import XCTest
import EssentialFeed

class URLSessionHttpClientTests: XCTestCase {
    
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromUrl_FailsOnRequestError() {
        let receivedError = resultErrorFor(data: nil, response: nil, error: anyNSError) as NSError?
        
        XCTAssertEqual(receivedError?.domain, anyNSError.domain)
        XCTAssertEqual(receivedError?.code, anyNSError.code)
    }
    
    func test_getFromUrl_FailsAllinvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPResponse, error: nil))
    }
    
    func test_getFromUrl_PerformGETRequestwithGivenUrl() {
        let url = anyUrl
        let exp = expectation(description: "Waiting the callback")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSut().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_getFromUrl_SucceedOnHTTPResponseAndData() {
        let givenData = anyData
        let givenResponse = anyHTTPResponse
        
        let result = resultValuesFor(data: givenData, response: givenResponse, error: nil)
        
        XCTAssertEqual(result.response?.statusCode, givenResponse.statusCode)
        XCTAssertEqual(result.response?.url, givenResponse.url)
        XCTAssertEqual(result.data, givenData)
    }
    
    func test_getFromUrl_SucceedWithEmptyDataHTTPResponseAndNilData() {
        let givenResponse = anyHTTPResponse
        
        let result = resultValuesFor(data: nil, response: givenResponse, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(result.data, emptyData)
        XCTAssertEqual(result.response?.statusCode, givenResponse.statusCode)
        XCTAssertEqual(result.response?.url, givenResponse.url)
    }
    
    // MARK: - Helpers
    
    private func makeSut(file: StaticString = #filePath, line: UInt = #line) -> HttpClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #filePath, line: UInt = #line) -> (response: HTTPURLResponse?, data: Data?) {
        
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        
        switch result {
            case .success((let receivedResponse, let receivedData)):
                return (receivedResponse, receivedData)
            default:
                XCTFail("Expected success with response \(String(describing: data)) and data \(String(describing: response)), got \(result) instead", file: file, line: line)
                return (nil, nil)
        }
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #filePath, line: UInt = #line) -> Error? {
        
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
            
        switch result {
            case .failure(let error):
                return error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
                return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #filePath, line: UInt = #line) -> HttpClient.Result {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "Waiting the callback")
        let sut = makeSut(file: file, line: line)
         
        var receivedResult: HttpClient.Result!
        
        sut.get(from: anyUrl) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
        return receivedResult
    }
    
    private var nonHTTPResponse: URLResponse {
        return URLResponse()
    }
    
    private var anyHTTPResponse: HTTPURLResponse {
        return HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private var anyData: Data {
        return Data()
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var observer: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            self.observer = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            observer = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let observer = URLProtocolStub.observer {
                client?.urlProtocolDidFinishLoading(self)
                return observer(request)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
