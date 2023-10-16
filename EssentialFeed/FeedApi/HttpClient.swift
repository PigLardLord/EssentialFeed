//
//  HttpClient.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 16/10/23.
//

import Foundation

public typealias HttpClientResult = Result<(HTTPURLResponse, Data), Error>

public protocol HttpClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
