//
// Created on 16/04/24 using Swift 5.0
//
        

import XCTest
import EssentialFeed

class RemoteFeedImageDataLoader {
    let client: HttpClient
    
    init(client: HttpClient) {
        self.client = client
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) {
        client.get(from: url) { _ in }
    }
}

final class RemoteFeedImageDataLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformAnyURLRequest() throws {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.messages.isEmpty)
    }
    
    func test_loadImageFromUrl_requestDataFromUrl() {
        let(sut, client) = makeSUT()
        let url = URL(string: "a-given-url")!
        
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(client.messages, [url])
    }
    
    //MARK: - Helpers
    
    private func makeSUT() -> (sut: RemoteFeedImageDataLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        return (sut, client)
    }
    
    private class HttpClientSpy: HttpClient {
        var messages: [URL] = []
        
        func get(from url: URL, completion: @escaping (HttpClient.Result) -> Void) {
            messages.append(url)
        }
    }
}

