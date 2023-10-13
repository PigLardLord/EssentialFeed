//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 11/10/23.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromTheUrl() {
        
        let (_, client) = makeSut()
        
        XCTAssertTrue(client.requestedUrls.isEmpty)
    }
    
    func test_load_requestDataFromUrl() {
        let url = URL(string: "a-given-url")!
        let (sut, client) = makeSut()
    
        sut.load()
        
        XCTAssertEqual(client.requestedUrls, [url])
    }
    
    func test_loadTwice_requestDataFromUrlTwice() {
        let url = URL(string: "a-given-url")!
        let (sut, client) = makeSut()
    
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedUrls, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSut()
        var capturedError: RemoteFeedLoader.Error?
        
        sut.load { error in capturedError = error }
        
        let error = NSError(domain: "Test", code: 0)
        client.complete(with: error)
            
        XCTAssertEqual(capturedError, .connectivity)
    }
    
    //MARK - heplers
    
    private func makeSut(url: URL = URL(string: "a-given-url")!) -> (sut:RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HttpClientSpy: HttpClient{
    
        var requestedUrls: [URL] = []
        var completions: [(Error) -> Void] = []
        
        func get(from url: URL, completion: @escaping (Error) -> Void){
            completions.append(completion)
            requestedUrls.append(url)
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index](error)
        }
    }
}
