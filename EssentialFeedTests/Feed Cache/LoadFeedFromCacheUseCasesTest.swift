//
//  LoadFeedFromCacheUseCasesTest.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 15/11/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCasesTest: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_loadFailOnCacheRetrievalError() {
        let (sut, store) = makeSUT()
        let desiredError = anyNSError
        
        var receivedError: Error? = nil
        let exp = expectation(description: "Waiting for store completion")
        sut.load { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeRetrievalWith(error: desiredError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(desiredError, receivedError as? NSError)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,  file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
    }
    
    private var anyNSError: NSError{
        return NSError(domain: "Any Error", code: 0)
    }
}
