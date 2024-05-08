//
// Created on 08/05/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import Foundation
import EssentialFeed

public class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private let decoratee: FeedImageDataLoader
    private let cache: FeedImageDataCache
    
    public init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        return decoratee.loadImageData(from: url) { [weak self] result in
            switch result {
                case let .success(imageData):
                    self?.cache.save(imageData, for: url, completion: {_ in})
                case .failure: break
            }
            completion(result)
        }
    }
}
