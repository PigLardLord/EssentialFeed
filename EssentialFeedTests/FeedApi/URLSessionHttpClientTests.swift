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
        session.dataTask(with: url) { _, _, _ in }
    }
}


class URLSessionHttpClientTests: XCTestCase {
    
    func test_getFromURL_createsDataTaskWithUrl() {
        let url = URL(string: "http://a_url.com")!
        let session = UrlSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    // MARK: - Helpers
    
    private class UrlSessionSpy: URLSession {
        var receivedURLs = [URL]()
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return UrlSessionDataTaskSpy()
        }
    }
    
    private class UrlSessionDataTaskSpy: URLSessionDataTask {}

}
