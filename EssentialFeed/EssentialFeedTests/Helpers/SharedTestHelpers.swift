//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 19/11/23.
//

import Foundation

var anyNSError: NSError{
    return NSError(domain: "Any Error", code: 0)
}

var anyUrl: URL {
    return URL(string: "http://a_url.com")!
}

var anyData: Data {
    return Data("any data".utf8)
}
