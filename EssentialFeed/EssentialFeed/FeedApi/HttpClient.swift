//
//  HttpClient.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 16/10/23.
//

import Foundation

public protocol HTTPClientTask {
    func cancel()
}

public protocol HttpClient {
    typealias Result = Swift.Result<(HTTPURLResponse, Data), Error>
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate thread if needed.
    @discardableResult
    func get(from url: URL, completion: @escaping (Result) -> Void) -> HTTPClientTask
}
