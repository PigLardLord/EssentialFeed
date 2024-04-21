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
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    private final class HTTPClientTaskWrapper: FeedImageDataLoaderTask {
        private var completion: ((FeedImageDataLoader.Result) -> Void)?
        
        var wrapped: HTTPClientTask?
        
        init(_ completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            preventFurtherCompletions()
            wrapped?.cancel()
        }
        
        private func preventFurtherCompletions() {
            completion = nil
        }
    }
    
    @discardableResult
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = HTTPClientTaskWrapper(completion)
        task.wrapped = client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
                case .failure(let error):  task.complete(with: .failure(error))
                case let .success((response, data)):
                    if response.statusCode == 200, !data.isEmpty {
                        task.complete(with: .success(data))
                    } else {
                        task.complete(with: .failure(Error.invalidData))
                    }
            }
        }
        
        return task
    }
}

final class RemoteFeedImageDataLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformAnyURLRequest() throws {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadImageFromUrl_requestDataFromUrl() {
        let(sut, client) = makeSUT()
        
        sut.loadImageData(from: anyUrl) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [anyUrl])
    }
    
    func test_loadImageDataFromUrl_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "a client error", code: 0)
        
        expect(sut, toCompleteWith: .failure(clientError), when: {
            client.complete(with: clientError)
        })
    }
    
    func test_loadImageDataFromUrl_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: code, data: anyData, at: index)
            })
        }
    }
    
    func test_loadImageDataFromUrlL_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let emptyData = Data()
            client.complete(withStatusCode: 200, data: emptyData)
        })
    }
    
    func test_loadImageDataFromUrl_deliversReceivedNonEmptyDataOn200HTTPResponse() {
        let (sut, client) = makeSUT()
        let nonEmptyData = Data("non-empty data".utf8)
        
        expect(sut, toCompleteWith: .success(nonEmptyData), when: {
            client.complete(withStatusCode: 200, data: nonEmptyData)
        })
    }
    
    func test_cancelLoadImageDataUrlTask_cancelsClientURLRequest() {
        let (sut, client) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        
        let task = sut.loadImageData(from: url) { _ in }
        XCTAssertTrue(client.cancelledURLs.isEmpty, "Expected no cancelled URL request until task is cancelled")
        
        task.cancel()
        XCTAssertEqual(client.cancelledURLs, [url], "Expected cancelled URL request after task is cancelled")
    }
    
    func test_loadImageDataFromUrl_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let client = HttpClientSpy()
        var sut: RemoteFeedImageDataLoader? = RemoteFeedImageDataLoader(client: client)
        
        var capturedResults = [FeedImageDataLoader.Result]()
        sut?.loadImageData(from: anyUrl) { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: anyData)
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask() {
        let (sut, client) = makeSUT()
        let nonEmptyData = Data("non-empty data".utf8)
        
        var received = [FeedImageDataLoader.Result]()
        let task = sut.loadImageData(from: anyUrl) { received.append($0) }
        task.cancel()
        
        client.complete(withStatusCode: 404, data: anyData)
        client.complete(withStatusCode: 200, data: nonEmptyData)
        client.complete(with: anyNSError)
        
        XCTAssertTrue(received.isEmpty, "Expected no received results after cancelling task")
    }
    
    //MARK: - Helpers
    
    private func makeSUT() -> (sut: RemoteFeedImageDataLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        return (sut, client)
    }
    
    private func failure(_ error: RemoteFeedImageDataLoader.Error) -> FeedImageDataLoader.Result {
        return .failure(error)
    }
    
    private func expect(_ sut: RemoteFeedImageDataLoader, toCompleteWith expectedResult: FeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let url = URL(string: "https://a-given-url.com")!
        let exp = expectation(description: "Wait for load completion")
        
        sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
                case let (.success(receivedData), .success(expectedData)):
                    XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                    
                case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                    XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                    
                default:
                    XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    
    private class HttpClientSpy: HttpClient {
        private struct Task: HTTPClientTask {
            let callback: () -> Void
            func cancel() { callback() }
        }
        
        private var messages = [(url: URL, completion: (HttpClient.Result) -> Void)]()
        private(set) var cancelledURLs = [URL]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HttpClient.Result) -> Void) -> HTTPClientTask {
            messages.append((url, completion))
            return Task { [weak self] in
                self?.cancelledURLs.append(url)
            }
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success((response, data)))
        }
    }
}

