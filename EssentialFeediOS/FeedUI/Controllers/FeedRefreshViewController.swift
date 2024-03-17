//
// Created on 12/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import UIKit

public final class FeedRefreshViewController: NSObject {
    public lazy var view = bound(UIRefreshControl())
    
    private let viewModel: FeedViewModel
    
    init(feedViewModel: FeedViewModel) {
        self.viewModel = feedViewModel
    }
    
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func bound(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingSatateChange = { [weak self] isLoading in
            if isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }
        
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
