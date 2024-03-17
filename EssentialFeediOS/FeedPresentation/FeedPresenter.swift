//
// Created on 17/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import EssentialFeed

struct FeedLoadingViewModel {
    let isLoading: Bool
}

protocol FeedLoadingView {
    func display(_ isLoading: FeedLoadingViewModel)
}

struct FeedViewModel {
    let feed: [FeedImage]
}

protocol FeedView {
    func display(_ feed: FeedViewModel)
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var feedView: FeedView?
    var loadingView: FeedLoadingView?
    
    func loadFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.feedView?.display(FeedViewModel(feed: feed))
            }
            self?.loadingView?.display(FeedLoadingViewModel(isLoading: false))
        }
    }
}
