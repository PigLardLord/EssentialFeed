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
    var requestUrl: URL?
    func get(from url: URL) {
        requestUrl = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromTheUrl() {
        let client = HttpClient()
        _ = RemoteFeedLoader(client: client)
        
        XCTAssertNil(client.requestUrl)
    }
    
    func test_load_requestDataFromUrl() {
        let client = HttpClient()
        let sut = RemoteFeedLoader(client: client)
    
        sut.load()
        
        XCTAssertNotNil(client.requestUrl)
    }
    
}
