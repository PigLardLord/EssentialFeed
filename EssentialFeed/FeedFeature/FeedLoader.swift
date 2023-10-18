//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 11/10/23.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedItem],Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
