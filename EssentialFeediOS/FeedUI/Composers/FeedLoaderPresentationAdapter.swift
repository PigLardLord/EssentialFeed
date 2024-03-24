//
// Created on 24/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import Foundation
import EssentialFeed

final class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    var presenter: FeedPresenter?
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func didRequestFeedRefresh() {
        presenter?.didStartLoadingFeed()
        feedLoader.load { [weak self] result in
            switch result {
            case let .success(feed):
                self?.presenter?.didfinishLoadingFeed(with: feed)
            case let .failure(error):
                self?.presenter?.didfinishLoadingFeed(with: error)
            }
        }
    }
}
