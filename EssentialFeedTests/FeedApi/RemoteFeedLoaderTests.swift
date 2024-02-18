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
        
        expect(sut, toCompleteWith: failure(.connectivity)) {
            let error = NSError(domain: "Test", code: 0)
            client.complete(with: error)
        }
    }
    
    func test_load_deliversErrorOnNot200HttpResponse() {
        let (sut, client) = makeSut()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { (index,status) in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let jsonData = makeJsonData([])
                client.complete(withStatusCode: status, data: jsonData, at: index)
            }
        }
    }

    func test_load_deliversErrorOn200HTTPResponseButInvalidJson() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWith: failure(.invalidData)) {
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
    
    func test_load_deliversFeedItemsOn200HTTPResponseWithJsonContainingItems() {
        let (sut, client) = makeSut()
        
        let item1 = makeItem(id: UUID(), image: "https://an_image.jpg")
            
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            image: "https://another_image.jpg"
        )
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items)) {
            let jsonData = makeJsonData([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: jsonData)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let client = HttpClientSpy()
        let url = URL(string: "http://any-url.com")!
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
        
        var capturedResults: [RemoteFeedLoader.FeedResult] = []
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeJsonData([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    
    //MARK - heplers
    
    private func makeSut(url: URL = URL(string: "a-given-url")!, file: StaticString = #filePath, line: UInt = #line) -> (sut:RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        return (sut, client)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, image: String) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(
            id: id,
            description: description,
            location: location,
            url: URL(string: image)!
        )
        
        let itemJson = [
            "id" : item.id.uuidString,
            "description" : item.description,
            "location" : item.location,
            "image" : item.url.absoluteString
        ].compactMapValues { $0 }
        
        return (item, itemJson)
    }
    
    private func makeJsonData(_ jsonArray: [[String : Any]]) -> Data {
        let payload = ["items": jsonArray]
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.FeedResult, file: StaticString = #filePath, line: UInt = #line, on action: ()->()) {
        let exp = expectation(description: "Waiting for the completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult){
                case let (.success(receivedItems), .success(expecterItems)):
                    XCTAssertEqual(receivedItems, expecterItems, file: file, line: line)
                case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                    XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                default:
                    XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.FeedResult{
        return .failure(error)
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
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
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
