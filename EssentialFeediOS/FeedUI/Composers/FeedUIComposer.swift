//
// Created on 17/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(loader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let refreshController = FeedRefreshViewController(feedLoader: loader)
        let feedController = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = {[weak feedController] feed in
            feedController?.tableModel = feed.map({ model in
                FeedImageCellController(model: model, imageLoader: imageLoader)
            })
            feedController?.tableView.reloadData()
        }
        return feedController
    }
}
