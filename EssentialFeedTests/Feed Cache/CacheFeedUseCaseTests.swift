//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 05/11/23.
//

import XCTest
import EssentialFeed

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] cacheDeletionError in
            guard let self else {return}
            
            if let cacheDeletionError {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(items, timestamp: currentDate()) { [weak self] error in
            guard let self else {return}
            
            completion(error)
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsDeletionOnCall() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeedItem])
    }
    
    func test_save_doesNotRequestItemsInsertionOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let deletionError =  anyNSError
        let (sut, store) = makeSUT()
        
        sut.save(items) { _ in }
        store.completeDeletionWith(error: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeedItem])
    }
    
    func test_save_requestItemInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        
        let (sut, store) = makeSUT(currentDate: { timestamp })
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeedItem, .insert(items, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let deletionError =  anyNSError
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletionWith(error: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let items = [uniqueItem(), uniqueItem()]
        let insertionError =  anyNSError
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertionWith(error: insertionError)
        }
    }
    
    func test_save_succedOnSuccessfulCacheInsertion() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store =  FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)
        
        var capturedErrors = [Error?]()
        sut?.save([]) { error in
            capturedErrors.append(error)
        }
        sut = nil
        store.completeDeletionWith(error: anyNSError)

        XCTAssertTrue(capturedErrors.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store =  FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)
        
        var capturedErrors = [Error?]()
        sut?.save([]) { error in
            capturedErrors.append(error)
        }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertionWith(error: anyNSError)

        XCTAssertTrue(capturedErrors.isEmpty)
    }
    
    //MARK: - Helpers
    
    private class FeedStoreSpy: FeedStore {
        enum ReceivedMessage: Equatable {
            case insert([FeedItem], Date)
            case deleteCachedFeedItem
        }
        
        private(set) var receivedMessages = [ReceivedMessage]()
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeedItem)
        }
        
        func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }
        
        func completeDeletionWith(error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completeInsertionWith(error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
    
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
        sut.save([uniqueItem(), uniqueItem()]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as? NSError, expectedError)
    }
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: nil, location: nil, image: anyUrl)
    }
    
    private var anyUrl: URL {
        return URL(string: "http://a_url.com")!
    }
    
    private var anyNSError: NSError{
        return NSError(domain: "Any Error", code: 0)
    }
}
