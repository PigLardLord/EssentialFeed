//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 11/10/23.
//

import Foundation

typealias LoadFeedResult = Result<[FeedItem],Error>

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
