//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 12/11/23.
//

import Foundation

public struct LocalFeedItem: Equatable, Decodable{
    public let id: UUID
    public let description: String?
    public let location: String?
    public let image: URL
    
    public init(id: UUID, description: String?, location: String?, image: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.image = image
    }
}
