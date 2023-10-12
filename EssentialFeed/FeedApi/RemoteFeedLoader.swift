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
    
    public init(client: HttpClient, url: URL){
        self.client = client
        self.url = url
    }
    
    public func load(){
        client.get(from: url)
    }
}

public protocol HttpClient {
    func get(from url: URL)
}
