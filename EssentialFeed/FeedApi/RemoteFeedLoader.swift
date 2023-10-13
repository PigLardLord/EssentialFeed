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
    
    public init(client: HttpClient, url: URL){
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Error) -> Void){
        client.get(from: url) { result in
            switch result{
                case .success:
                    completion(.invalidData)
                case .failure:
                    completion(.connectivity)
            }
        }
    }
}

// MARK - interface

public typealias HttpClientResult = Result<HTTPURLResponse, Error>

public protocol HttpClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
