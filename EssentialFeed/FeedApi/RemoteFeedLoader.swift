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
                case .success(( _ , let data)):
                    let decoder = JSONDecoder()
                    if let root = try? decoder.decode(RootNode.self, from: data){
                        completion(.success(root.items))
                    } else {
                        completion(.failure(.invalidData))
                    }
                case .failure:
                    completion(.failure(.connectivity))
            }
        }
    }
    
    private struct RootNode: Decodable {
        var items: [FeedItem]
    }
}



// MARK - interface
public typealias HttpClientResult = Result<(HTTPURLResponse, Data), Error>

public protocol HttpClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
