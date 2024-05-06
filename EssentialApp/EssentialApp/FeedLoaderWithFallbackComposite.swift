//
// Created on 06/05/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import EssentialFeed

public class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader

    public init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        primary.load { [weak self] result in
            switch result {
                case .success: completion(result)
                case .failure: self?.fallback.load(completion: completion)
            }
        }
    }
}
