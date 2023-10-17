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
        
        var feed: [FeedItem] {
            return items.map{ $0.item }
        }
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
    
    static func getResult(from response: HTTPURLResponse, and data: Data ) -> RemoteFeedLoader.FeedResult {
        let decoder = JSONDecoder()
        guard 
            response.statusCode == 200,
            let root = try? decoder.decode(RootNode.self, from: data)
        else {
            return .failure(.invalidData)
        }
        
        return .success(root.feed)
    }
}
