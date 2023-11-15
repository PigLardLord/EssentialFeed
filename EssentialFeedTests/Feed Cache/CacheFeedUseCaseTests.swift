//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 05/11/23.
//

import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsDeletionOnCall() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueImageFeed().model) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestItemsInsertionOnDeletionError() {
        let deletionError =  anyNSError
        let (sut, store) = makeSUT()
        
        sut.save(uniqueImageFeed().model) { _ in }
        store.completeDeletionWith(error: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestItemInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let feed = uniqueImageFeed()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        sut.save(feed.model) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let deletionError =  anyNSError
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletionWith(error: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let insertionError =  anyNSError
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertionWith(error: insertionError)
        }
    }
    
    func test_save_succedOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store =  FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)
        
        var capturedErrors = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().model) { error in
            capturedErrors.append(error)
        }
        sut = nil
        store.completeDeletionWith(error: anyNSError)

        XCTAssertTrue(capturedErrors.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store =  FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)
        
        var capturedErrors = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().model) { error in
            capturedErrors.append(error)
        }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertionWith(error: anyNSError)

        XCTAssertTrue(capturedErrors.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,  file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, file: StaticString = #filePath, line: UInt = #line, when action: () -> Void) {
        let exp = expectation(description: "Wait for save completed")
        
        var receivedError: Error?
        sut.save(uniqueImageFeed().model) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as? NSError, expectedError)
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: nil, location: nil, url: anyUrl)
    }
    
    private func uniqueImageFeed() -> (model: [FeedImage], local: [LocalFeedImage]) {
        let items = [uniqueImage(), uniqueImage()]
        let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        return (items, localItems)
    }
    
    private var anyUrl: URL {
        return URL(string: "http://a_url.com")!
    }
    
    private var anyNSError: NSError{
        return NSError(domain: "Any Error", code: 0)
    }
}
