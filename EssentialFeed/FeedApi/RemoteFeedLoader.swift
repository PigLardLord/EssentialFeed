//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 12/10/23.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
   
    private let client: HttpClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias FeedResult = LoadFeedResult
    
    public init(client: HttpClient, url: URL){
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (FeedResult) -> Void){
        client.get(from: url) { [weak self] result in
            guard let self else {return}
            
            switch result{
                case .success(( let response , let data)):
                    completion(FeedItemsMapper.getResult(from: response, and: data))
                case .failure:
                    completion(.failure(Error.connectivity))
            }
        }
    }
}
