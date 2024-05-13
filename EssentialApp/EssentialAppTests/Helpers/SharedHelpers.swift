//
// Created on 06/05/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import Foundation
import EssentialFeed

var anyData: Data {
    return Data("any data".utf8)
}

var anyURL: URL {
    return URL(string: "http://a-url.com")!
}

var anyNSError: NSError {
    return NSError(domain: "any error", code: 0)
}

func uniqueFeed() -> [FeedImage] {
    return [FeedImage(id: UUID(), description: "any", location: "any", url: URL(string: "http://any-url.com")!)]
}
