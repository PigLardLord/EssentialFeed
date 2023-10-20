//
//  XCTestCase+MemoryleakTracking.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 20/10/23.
//

import XCTest

extension XCTestCase {

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential leak", file: file, line: line)
        }
    }
}
