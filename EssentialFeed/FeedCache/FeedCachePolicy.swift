//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 21/11/23.
//

import Foundation

final class FeedCachePolicy {
    static let calendar = Calendar(identifier: .gregorian)
    
    private init() {}
    
    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
