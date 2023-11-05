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
    
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    
    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func insert(_ items: [FeedItem]) {
        insertCallCount += 1
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
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]){
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items)
            }
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestsDeletionOnCall() {
        let items = [uniqueItem(), uniqueItem()]
        
        let (sut, store) = makeSUT()
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestItemsInsertionOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let deletionError =  anyNSError
        
        let (sut, store) = makeSUT()
        sut.save(items)
        store.completeDeletionWith(error: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_requestItemInsertionOnSuccessfulDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        
        let (sut, store) = makeSUT()
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let loader = LocalFeedLoader(store: store)
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
