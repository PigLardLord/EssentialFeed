//
//  XCTestCase+FailableStoreInsertion.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 04/12/23.
//

import XCTest
import EssentialFeed

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
