//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 11/10/23.
//

import XCTest

class RemoteFeedLoader {
    private let client: HttpClient
    
    init(client: HttpClient){
        self.client = client
    }
    
    func load(){
        client.get(from: URL(string: "url")!)
    }
}

class HttpClient {
    func get(from url: URL) {
    }
}

class HttpClientSpy: HttpClient{
    var requestUrl: URL?
    override func get(from url: URL) {
        requestUrl = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromTheUrl() {
        let client = HttpClientSpy()
        _ = RemoteFeedLoader(client: client)
        
        XCTAssertNil(client.requestUrl)
    }
    
    func test_load_requestDataFromUrl() {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client)
    
        sut.load()
        
        XCTAssertNotNil(client.requestUrl)
    }
    
}
