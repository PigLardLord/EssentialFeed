//
// Created on 17/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        
import Foundation
import EssentialFeed

protocol FeedLoadingView {
    func display(_ isLoading: FeedLoadingViewModel)
}

protocol FeedView {
    func display(_ feed: FeedViewModel)
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void
    
    private let feedView: FeedView
    private let loadingView: FeedLoadingView
    
    init(feedView: FeedView, loadingView: FeedLoadingView) {
        self.feedView = feedView
        self.loadingView = loadingView
    }
    
    static var title: String {
        return String(localized: "FEED_VIEW_TITLE", table: "Feed", bundle: Bundle(for: FeedPresenter.self), comment: "Title for the feed view")
    }
    
    func didStartLoadingFeed() {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async { [weak self] in self?.didStartLoadingFeed() }
        }
        
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didfinishLoadingFeed(with feed: [FeedImage]) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async { [weak self] in self?.didfinishLoadingFeed(with: feed) }
        }
        
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didfinishLoadingFeed(with error: Error) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async { [weak self] in self?.didfinishLoadingFeed(with: error) }
        }
        
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}
