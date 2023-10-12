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
        
        XCTAssertNil(client.requestUrl)
    }
    
    func test_load_requestDataFromUrl() {
        let url = URL(string: "a-given-url")!
        let (sut, client) = makeSut()
    
        sut.load()
        
        XCTAssertEqual(client.requestUrl, url)
    }
    
    //MARK - heplers
    
    private func makeSut(url: URL = URL(string: "a-given-url")!) -> (sut:RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HttpClientSpy: HttpClient{
        var requestUrl: URL?
        
        func get(from url: URL) {
            requestUrl = url
        }
    }
}
