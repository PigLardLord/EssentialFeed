//
//  XCTestCase+FailableStoreInsertion.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 04/12/23.
//

import XCTest
import EssentialFeed

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetireveDeliversFailureOnRetrievalError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: .failure(error: anyNSError))
    }
    
    func assertThatRetireveHasNoSideEffectsOnFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .failure(error: anyNSError))
    }
}

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line){
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert(feed, with: timestamp, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected insertion fail with an error")
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line){
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert(feed, with: timestamp, to: sut)

        expect(sut, toRetrieve: .empty)
    }
}

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty)
    }
}
