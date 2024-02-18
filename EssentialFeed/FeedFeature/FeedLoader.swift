//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 11/10/23.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage],Error>
    func load(completion: @escaping (Result) -> Void)
}
