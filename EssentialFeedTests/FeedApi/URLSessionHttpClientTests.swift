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
    
    init(session: URLSession) {
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
    
    func test_getFromURL_resumesDataTaskWithUrl() {
        let url = URL(string: "http://a_url.com")!
        let session = UrlSessionSpy()
        let task = UrlSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url){ _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromUrl_FailsOnRequestError() {
        let url = URL(string: "http://a_url.com")!
        let session = UrlSessionSpy()
        let task = UrlSessionDataTaskSpy()
        let expectedError = NSError(domain: "test", code: 0)
        session.stub(url: url, task: task, error: expectedError)
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Waiting the callback")
        sut.get(from: url) { result in
            switch result {
                case .failure(let receivedError as NSError):
                    XCTAssertEqual(receivedError, expectedError)
                default:
                    XCTFail("Expected failure with error \(expectedError), got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: - Helpers
    
    private class UrlSessionSpy: URLSession {
        private var stubs = [URL : Stub]()
        
        override init() {}
        
        private struct Stub {
            let task: URLSessionDataTask
            let error: Error?
        }
        
        func stub(url: URL, task: URLSessionDataTask, error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("couldn't find the stub for url \(url)")
            }
            
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    
    
    private class UrlSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override init() {}
        
        override func resume() {
            resumeCallCount += 1
        }
    }

}
