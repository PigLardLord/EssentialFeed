//
// Created on 17/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(loader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let viewModel = FeedViewModel(feedLoader: loader)
        let refreshController = FeedRefreshViewController(feedViewModel: viewModel)
        let feedController = FeedViewController(refreshController: refreshController)
        viewModel.onFeedLoad = adaptFeedToCellControllers(forwordingTo: feedController, loader: imageLoader)
        return feedController
    }
    
    private static func adaptFeedToCellControllers(forwordingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] feed in
            controller?.tableModel = feed.map({ model in
                let viewModel = FeedImageViewModel(model: model, imageLoader: loader)
                return FeedImageCellController(viewModel: viewModel)
            })
        }
    }
}
