//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 11/10/23.
//

import XCTest

class RemoteFeedLoader {
    
}

class HttpClient {
    var requestUrl: URL?
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromTheUrl() {
        let client = HttpClient()
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestUrl)
    }
    
}
