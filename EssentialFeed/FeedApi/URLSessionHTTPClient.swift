//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Giovanni Trovato on 21/10/23.
//

import Foundation

public final class URLSessionHTTPClient: HttpClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
    public func get(from url: URL, completion: @escaping (HttpClient.Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            completion( Result {
                if let error {
                    throw error
                } else if let data, let response, let hTTPResponse = response as? HTTPURLResponse {
                    return (hTTPResponse, data)
                } else {
                    throw UnexpectedValuesRepresentation()
                }
            })
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}
