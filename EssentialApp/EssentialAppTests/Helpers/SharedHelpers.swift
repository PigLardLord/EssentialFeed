//
// Created on 06/05/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import Foundation

var anyData: Data {
    return Data("any data".utf8)
}

var anyURL: URL {
    return URL(string: "http://a-url.com")!
}

var anyNSError: NSError {
    return NSError(domain: "any error", code: 0)
}
