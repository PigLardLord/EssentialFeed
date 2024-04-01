//
// Created on 01/04/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

struct FeedErrorViewModel {
    let message: String?
    
    static var noError: FeedErrorViewModel {
        return FeedErrorViewModel(message: nil)
    }

    static func error(message: String) -> FeedErrorViewModel {
        return FeedErrorViewModel(message: message)
    }
}
