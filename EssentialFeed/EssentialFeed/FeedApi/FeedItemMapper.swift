//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 16/10/23.
//

import Foundation

final class FeedItemsMapper {
    private struct RootNode: Decodable {
        var items: [RemoteFeedItem]
    }

    static func getResult(from response: HTTPURLResponse, and data: Data ) throws -> [RemoteFeedItem] {
        let decoder = JSONDecoder()
        guard response.isOK, let root = try? decoder.decode(RootNode.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
