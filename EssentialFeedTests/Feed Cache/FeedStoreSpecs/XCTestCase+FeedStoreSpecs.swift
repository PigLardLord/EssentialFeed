//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 04/12/23.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetireveDeliversEmptyOnEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        expect(sut, toRetrieve: .success(.none), file: file, line: line)
    }
    
    func assertThatRetireveHasNoSideEffectOnEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        expect(sut, toRetrieveTwice: .success(.none), file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, with: timestamp, to: sut)
        
        expect(sut, toRetrieve: .success(CachedFeed(feed: feed, timestamp: timestamp)), file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, with: timestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .success(CachedFeed(feed: feed, timestamp: timestamp)), file: file, line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        let insertionError = insert(uniqueImageFeed().local, with: Date(), to: sut)

        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        insert(uniqueImageFeed().local, with: Date(), to: sut)

        let insertionError = insert(uniqueImageFeed().local, with: Date(), to: sut)

        XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        insert(uniqueImageFeed().local, with: Date(), to: sut)

        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert(latestFeed, with: latestTimestamp, to: sut)

        expect(sut, toRetrieve: .success(CachedFeed(feed: latestFeed, timestamp: latestTimestamp)), file: file, line: line)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        deleteCache(from: sut)

        expect(sut, toRetrieve: .success(.none), file: file, line: line)
    }
    
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        insert(uniqueImageFeed().local, with: Date(), to: sut)

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        insert(uniqueImageFeed().local, with: Date(), to: sut)

        deleteCache(from: sut)

        expect(sut, toRetrieve: .success(.none), file: file, line: line)
    }
    
    func assertThatStoreSideEffectsRunSerially(on sut: FeedStore,file: StaticString = #filePath, line: UInt = #line){
        var completedOperationsInOrder = [XCTestExpectation]()

        let operation1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation1)
            operation1.fulfill()
        }
        
        let operation2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(operation2)
            operation2.fulfill()
        }
        
        let operation3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation3)
            operation3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperationsInOrder, [operation1, operation2, operation3], "Expected side-effects to run serially but completed in the wrong order", file: file, line: line)
    }
    
}

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func insert(_ feed: [LocalFeedImage], with timestamp: Date, to sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let exp = expectation(description: "wait for insertion")
        var capturedInsertionError: Error? = nil
        sut.insert(feed, timestamp: timestamp) { insertResult in
            if case let Result.failure(error) = insertResult {
                capturedInsertionError = error
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedInsertionError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let exp = expectation(description: "wait for deletion")
        var capturedDeletionError: Error? = nil
        sut.deleteCachedFeed { deletionResult in
            if case let Result.failure(error) = deletionResult {
                capturedDeletionError = error
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedDeletionError
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: FeedStore.RetrievalResult, file: StaticString = #filePath, line: UInt = #line){
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: FeedStore.RetrievalResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for retrieval")
        
        sut.retrieve { retrieveResult in
            switch (expectedResult, retrieveResult) {
                case (.success(.none), .success(.none)), (.failure, .failure):
                    break
                case let (.success(.some(expected)), .success(.some(retrieved))):
                    XCTAssertEqual(retrieved.feed, expected.feed, file: file, line: line)
                    XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)
                default:
                    XCTFail("Expected retrieval with \(expectedResult), got \(retrieveResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
