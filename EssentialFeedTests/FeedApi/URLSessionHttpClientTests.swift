//
//  URLSessionHttpClientTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 18/10/23.
//

import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        let task = session.dataTask(with: url) { _, _, _ in }
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
        
        sut.get(from: url)
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private class UrlSessionSpy: URLSession {
        private var stubs = [URL : URLSessionDataTask]()
        
        func stub(url: URL, task: URLSessionDataTask) {
            stubs[url] = task
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            return stubs[url] ?? UrlSessionDataTaskSpy()
        }
    }
    
    private class UrlSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }

}
