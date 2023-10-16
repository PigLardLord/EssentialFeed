//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 16/10/23.
//

import Foundation

final class FeedItemsMapper {
    private struct RootNode: Decodable {
        var items: [Item]
    }

    private struct Item: Equatable, Decodable{
        public let id: UUID
        public let description: String?
        public let location: String?
        public let image: URL
        
        var item: FeedItem {
            return FeedItem(
                id: id,
                description: description,
                location: location,
                image: image
            )
        }
    }
    
    static func map(_ response: HTTPURLResponse, _ data: Data ) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        let decoder = JSONDecoder()
        let root = try decoder.decode(RootNode.self, from: data)
        return root.items.map{ $0.item }
    }
}
