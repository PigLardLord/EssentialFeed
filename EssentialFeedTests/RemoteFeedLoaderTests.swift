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
    
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedUrls, [url])
    }
    
    func test_loadTwice_requestDataFromUrlTwice() {
        let url = URL(string: "a-given-url")!
        let (sut, client) = makeSut()
    
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedUrls, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSut()
        var capturedError: [RemoteFeedLoader.Error] = []
        
        sut.load { capturedError.append($0) }
        
        let error = NSError(domain: "Test", code: 0)
        client.complete(with: error)
            
        XCTAssertEqual(capturedError, [.connectivity])
    }
    
    func test_load_deliversErrorOnNot200HttpResponse() {
        let (sut, client) = makeSut()
        var samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { (index,status) in
            var capturedError: [RemoteFeedLoader.Error] = []
            sut.load { capturedError.append($0) }
            
            client.complete(withStatusCode: status, at: index)
            XCTAssertEqual(capturedError, [.invalidData])
        }
    }
    
    //MARK - heplers
    
    private func makeSut(url: URL = URL(string: "a-given-url")!) -> (sut:RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HttpClientSpy: HttpClient {
       
        
        var messages: [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)] = []
        
        var requestedUrls: [URL] {
            return messages.map {
                $0.url
            }
        }
        
        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }
        
        func complete(withStatusCode code: Int, at index: Int = 0) {
            let response =  HTTPURLResponse(
                url: requestedUrls[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )
            
            messages[index].completion(nil, response)
        }
    }
}
