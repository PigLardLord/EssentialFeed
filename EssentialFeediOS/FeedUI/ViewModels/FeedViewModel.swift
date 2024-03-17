//
// Created on 17/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import Foundation
import EssentialFeed

final class FeedViewModel {
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?
    
    private(set) var isLoading = false {
        didSet { onChange?(self) }
    }
    
    func loadFeed() {
        isLoading =  true
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            } 
            self?.isLoading = false
        }
    }
}
