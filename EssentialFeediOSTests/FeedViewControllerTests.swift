//
// Created on 27/02/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import XCTest

final class FeedViewController {
    init(loader: FeedViewControllerTests.LoaderSpy) {
        
    }
}


final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    class LoaderSpy {
        var loadCallCount: Int = 0
        
        func load() {
            loadCallCount += 1
        }
    }

}
