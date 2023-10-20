//
//  URLSessionHttpClientTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 18/10/23.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        let task = session.dataTask(with: url) { _, _, error in
            if let error{
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        task.resume()
    }
}


class URLSessionHttpClientTests: XCTestCase {
    
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromUrl_FailsOnRequestError() {
        let expectedError = NSError(domain: "test", code: 0)
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: expectedError) as NSError?
        
        XCTAssertEqual(receivedError?.domain, expectedError.domain)
        XCTAssertEqual(receivedError?.code, expectedError.code)
    }
    
    func test_getFromUrl_FailsAllinvalidRepresentationCases() {
        let nonHTTPResponse = URLResponse()
        let anyHTTPResponse = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data()
        let anyError = NSError(domain: "Any Error", code: 0)
        
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPResponse, error: anyError))
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
    
    // MARK: - Helpers
    
    private func makeSut(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient{
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #filePath, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "Waiting the callback")
        let sut = makeSut(file: file, line: line)
        
        var receivedError: Error?
        sut.get(from: anyUrl) { result in
            switch result {
                case .failure(let error):
                    receivedError = error
                default:
                    XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        
        return receivedError
    }
    
    private var anyUrl: URL {
        return URL(string: "http://a_url.com")!
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
            observer?(request)
            return request
        }
        
        override func startLoading() {
            if let response = URLProtocolStub.stub?.response{
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
