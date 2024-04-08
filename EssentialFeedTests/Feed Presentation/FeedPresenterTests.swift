//
// Created on 08/04/24 using Swift 5.0
//
        

import XCTest

final class FeedPresenter {
    init(view: Any) {
        
    }
}


final class FeedPresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessagesToView() {
        let view = ViewSpy()
        
        _ = FeedPresenter(view: view)
        
        XCTAssertTrue(view.messages.isEmpty, "Expected no view messages")
    }
    
    //MARK: - Helpers
    
    private class ViewSpy {
        let messages = [Any]()
    }
    
}
