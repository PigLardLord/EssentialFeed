//
//  CodableEssentialFeedTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 26/11/23.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {
    
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
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retireve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retireve_deliversInsertedValuesAfterSuccessfulInsertion() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, with: timestamp, to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retireve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, with: timestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    func test_retireve_deliversFailureOnRetrievalError() {
        let storeUrl = testSpecificimageFeedUrl
        let sut = makeSUT(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(error: anyNSError))
    }
    
    func test_retireve_deliversSameFailureOnTwiceRetrievalError() {
        let storeUrl = testSpecificimageFeedUrl
        let sut = makeSUT(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(error: anyNSError))
    }
    
    func test_insert_overridesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        let firstError = insert(uniqueImageFeed().local, with: Date(), to: sut)
        XCTAssertNil(firstError, "Expected no insertion Error, got \(firstError!) instead")
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let secondError = insert(latestFeed, with: latestTimestamp, to: sut)
        
        XCTAssertNil(secondError, "Expected no insertion Error, got \(secondError!) instead")
        expect(sut, toRetrieveTwice: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let storeUrl = URL(string: "invalid:/store-url!")
        let sut = makeSUT(storeUrl: storeUrl)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert(feed, with: timestamp, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected insertion fail with an error")
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        let error = deleteCache(from: sut)
        
        XCTAssertNil(error, "Expected no error deleting empty cache")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_wipePreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert(feed, with: timestamp, to: sut)
        
        let error = deleteCache(from: sut)
        
        XCTAssertNil(error, "Expected no error deleting cache")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnInsertionError() {
        let noDeletePermossionUrl = cachesDirectory
        let sut = makeSUT(storeUrl: noDeletePermossionUrl)
        
        let error = deleteCache(from: sut)
        
        XCTAssertNotNil(error, "Expected deletion fails with an error")
    }
    
    //MARK: - Helpers
    
    private func makeSUT(storeUrl: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let url = storeUrl ?? testSpecificimageFeedUrl
        let sut = CodableFeedStore(storeUrl: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    @discardableResult
    private func insert(_ feed: [LocalFeedImage], with timestamp: Date, to sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let exp = expectation(description: "wait for insertion")
        var capturedInsertionError: Error? = nil
        sut.insert(feed, timestamp: timestamp) { insertionError in
            capturedInsertionError = insertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedInsertionError
    }
    
    @discardableResult
    private func deleteCache(from sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let exp = expectation(description: "wait for deletion")
        var capturedDeletionError: Error? = nil
        sut.deleteCachedFeed { deletionError in
            capturedDeletionError = deletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedDeletionError
    }
    
    private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line){
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for retrieval")
        
        sut.retrieve { retrieveResult in
            switch (expectedResult, retrieveResult) {
                case (.empty, .empty), (.failure, .failure):
                    break
                case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                    XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                    XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
                default:
                    XCTFail("Expected retrieval with \(expectedResult), got \(retrieveResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private var testSpecificimageFeedUrl: URL {
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
        try? FileManager.default.removeItem(at: testSpecificimageFeedUrl)
    }

}

