//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 19/11/23.
//

import Foundation
import EssentialFeed

var anyNSError: NSError{
    return NSError(domain: "Any Error", code: 0)
}

func uniqueImageFeed() -> (model: [FeedImage], local: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    return (items, localItems)
}

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: nil, location: nil, url: anyUrl)
}

var anyUrl: URL {
    return URL(string: "http://a_url.com")!
}

extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
