//
//  CodableEssentialFeedTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 26/11/23.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase,  FailableFeedStore {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_retireve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetireveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retireve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetireveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetireveHasNoSideEffectOnEmptyCache(on: sut)
    }

    func test_retireve_deliversFailureOnRetrievalError() {
        let storeUrl = testSpecificImageFeedUrl
        let sut = makeSUT(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(error: anyNSError))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeUrl = testSpecificImageFeedUrl
        let sut = makeSUT(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(error: anyNSError))
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }

    func test_insert_deliversErrorOnInsertionError() {
        let storeUrl = URL(string: "invalid:/store-url!")
        let sut = makeSUT(storeUrl: storeUrl)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert(feed, with: timestamp, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected insertion fail with an error")
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeUrl: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert(feed, with: timestamp, to: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(storeUrl: noDeletePermissionURL)

        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }

    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(storeUrl: noDeletePermissionURL)

        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        
        assertThatStoreSideEffectsRunSerially(on: sut)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(storeUrl: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let url = storeUrl ?? testSpecificImageFeedUrl
        let sut = CodableFeedStore(storeUrl: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private var testSpecificImageFeedUrl: URL {
        return cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificImageFeedUrl)
    }

}
