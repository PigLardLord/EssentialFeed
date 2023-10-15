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
        
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let error = NSError(domain: "Test", code: 0)
            client.complete(with: error)
        }
    }
    
    func test_load_deliversErrorOnNot200HttpResponse() {
        let (sut, client) = makeSut()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { (index,status) in
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                client.complete(withStatusCode: status, at: index)
            }
        }
    }

    func test_load_deliversErrorOn200HTTPResponseButInvalidJson() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidJson = Data("invalid".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    
    func test_load_deliversnoItemsOn200HTTPResponseWithEmptyJson() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWith: .success([])) {
            let emptyJson = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyJson)
        }
    }
    
    //MARK - heplers
    
    private func makeSut(url: URL = URL(string: "a-given-url")!) -> (sut:RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.FeedResult, file: StaticString = #filePath, line: UInt = #line, on action: ()->()) {
        
        var capturedResults: [RemoteFeedLoader.FeedResult] = []
        
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    private class HttpClientSpy: HttpClient {
       
        
        var messages: [(url: URL, completion: (HttpClientResult) -> Void)] = []
        
        var requestedUrls: [URL] {
            return messages.map {
                $0.url
            }
        }
        
        func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response =  HTTPURLResponse(
                url: requestedUrls[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            
            messages[index].completion(.success((response, data)))
        }
    }
}
