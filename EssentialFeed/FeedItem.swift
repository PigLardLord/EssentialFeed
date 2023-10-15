//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 11/10/23.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
