//
//  HttpClient.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 16/10/23.
//

import Foundation

public typealias HttpClientResult = Result<(HTTPURLResponse, Data), Error>

public protocol HttpClient {
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate thread if needed.
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
