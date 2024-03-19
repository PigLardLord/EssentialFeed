//
// Created on 10/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import UIKit
import EssentialFeediOS

extension FeedViewController {
    func simulateAppereance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFake()
        }
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at row: Int) -> FeedImageCell? {
        return feedImageView(at: row) as? FeedImageCell
    }
    
    func simulateFeedImageViewNotVisible(at row: Int) {
        let view = simulateFeedImageViewVisible(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewWillDisplay(at row: Int) {
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedSection)
        delegate?.tableView?(tableView, willDisplay: UITableViewCell(), forRowAt: index)
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
    
    func simulateUserInitiatedReload() {
        refreshController?.view?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshController?.view?.isRefreshing == true
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        return tableView.numberOfRows(inSection: feedSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    private var feedSection: Int { 0 }
}

//MARK: - FakeRefreshControl helper

extension FeedViewController {
    private func replaceRefreshControlWithFake() {
        let fake = FakeRefreshControl()
        
        refreshController?.view?.allTargets.forEach({ target in
            refreshController?.view?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                fake.addTarget(target, action: Selector($0), for: .valueChanged)
            }
        })
        
        refreshController?.view = fake
    }
}
