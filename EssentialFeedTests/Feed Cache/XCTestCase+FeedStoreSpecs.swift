//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 04/12/23.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func insert(_ feed: [LocalFeedImage], with timestamp: Date, to sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
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
    func deleteCache(from sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let exp = expectation(description: "wait for deletion")
        var capturedDeletionError: Error? = nil
        sut.deleteCachedFeed { deletionError in
            capturedDeletionError = deletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedDeletionError
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line){
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
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
}
