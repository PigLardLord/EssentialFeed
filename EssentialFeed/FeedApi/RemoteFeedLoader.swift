//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 12/10/23.
//

import Foundation

public final class RemoteFeedLoader {
    private let client: HttpClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias FeedResult = Result<[FeedItem], Error>
    
    public init(client: HttpClient, url: URL){
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (FeedResult) -> Void){
        client.get(from: url) { result in
            switch result{
                case .success(( let response , let data)):
                    guard let items = try? FeedItemsMapper.map(response, data) else {
                        completion(.failure(.invalidData))
                        return
                    }
                    
                    completion(.success(items))
                case .failure:
                    completion(.failure(.connectivity))
            }
        }
    }
}
