//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 05/11/23.
//

import XCTest
import EssentialFeed

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable {
        case insert([FeedItem], Date)
        case deleteCachedFeedItem
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeedItem)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeDeletionWith(error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]){
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                store.insert(items, timestamp: currentDate())
            }
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
        sut.save(items)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeedItem])
    }
    
    func test_save_doesNotRequestItemsInsertionOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let deletionError =  anyNSError
        
        let (sut, store) = makeSUT()
        sut.save(items)
        store.completeDeletionWith(error: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeedItem])
    }
    
    func test_save_requestItemInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        
        let (sut, store) = makeSUT(currentDate: { timestamp })
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeedItem, .insert(items, timestamp)])
    }
    
    
    //MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,  file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let loader = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
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
