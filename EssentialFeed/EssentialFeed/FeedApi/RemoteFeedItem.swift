//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 12/11/23.
//

import Foundation

struct RemoteFeedItem: Equatable, Decodable{
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
