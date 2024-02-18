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
    
    public typealias FeedResult = FeedLoader.Result
    
    public init(client: HttpClient, url: URL){
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (FeedResult) -> Void){
        client.get(from: url) { [weak self] result in
            guard self != nil else {return}
            
            switch result{
                case .success(( let response , let data)):
                    completion(RemoteFeedLoader.map(response, data))
                case .failure:
                    completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ response: HTTPURLResponse, _ data: Data) -> FeedResult {
        do {
            let items = try FeedItemsMapper.getResult(from: response, and: data)
            return .success(items.toModels())
        } catch let error {
            return .failure(error)
        }
    }
    
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}
