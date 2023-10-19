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
    
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        let task = session.dataTask(with: url) { _, _, error in
            if let error{
                completion(.failure(error))
            }
        }
        task.resume()
    }
}


class URLSessionHttpClientTests: XCTestCase {
    
    func test_getFromUrl_FailsOnRequestError() {
        
        URLProtocolStub.startInterceptingRequests()
        
        let url = URL(string: "http://a_url.com")!
        let expectedError = NSError(domain: "test", code: 0)
        URLProtocolStub.stub(url: url, error: expectedError)
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Waiting the callback")
        sut.get(from: url) { result in
            switch result {
                case .failure(let receivedError as NSError):
                    XCTAssertEqual(receivedError.domain, expectedError.domain)
                    XCTAssertEqual(receivedError.code, expectedError.code)
                default:
                    XCTFail("Expected failure with error \(expectedError), got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        URLProtocolStub.stopInterceptingRequests()
    }
    
    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        private static var stubs = [URL : Stub]()
        
        private struct Stub {
            let error: Error?
        }
        
        static func stub(url: URL, error: Error? = nil) {
            stubs[url] = Stub(error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            
            return stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard 
                let url = request.url,
                let stub = URLProtocolStub.stubs[url]
            else { return }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() {}
    }
}
