//
// Created on 09/05/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import XCTest
import EssentialFeed
import EssentialFeediOS
@testable import EssentialApp

class FeedAcceptanceTests: XCTestCase {
    
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let feed = launch(httpClient: .online(response), store: .empty)
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), stubbedImageData)
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), stubbedImageData)
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let sharedStore = InMemoryFeedStore.empty
        let onlineFeed = launch(httpClient: .online(response), store: sharedStore)
        onlineFeed.simulateFeedImageViewVisible(at: 0)
        onlineFeed.simulateFeedImageViewVisible(at: 1)
        
        let offlineFeed = launch(httpClient: .offline, store: sharedStore)

        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), stubbedImageData)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), stubbedImageData)
    }
    
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let feed = launch(httpClient: .offline, store: .empty)
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 0)
    }
    
    func test_onEnteringBackground_deletesExpiredFeedCache() {
        let store = InMemoryFeedStore.withExpiredFeedCache
        
        enterBackground(with: store)

        XCTAssertNil(store.feedCache, "Expected to delete expired cache")
    }
    
    func test_onEnteringBackground_keepsNonExpiredFeedCache() {
        let store = InMemoryFeedStore.withNonExpiredFeedCache
        
        enterBackground(with: store)
        
        XCTAssertNotNil(store.feedCache, "Expected to keep non-expired cache")
    }

    
    // MARK: - Helpers

    private func launch(httpClient: HTTPClientStub = .offline, store: InMemoryFeedStore = .empty) -> FeedViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()
        
        let nav = sut.window?.rootViewController as? UINavigationController
        let listViewContoller = nav?.topViewController as! FeedViewController
        listViewContoller.simulateAppereance()
        return listViewContoller
    }
    
    private func enterBackground(with store: InMemoryFeedStore) {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline, store: store)
        sut.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
    }
    
    private func response(for url: URL) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, makeData(for: url))
    }
    
    private func makeData(for url: URL) -> Data {
        switch url.absoluteString {
            case "http://image.com": return stubbedImageData
            default: return stubbedFeedData
        }
    }
    
    private var stubbedImageData: Data {
        return UIImage.make(withColor: .red).pngData()!
    }
    
    private var stubbedFeedData: Data {
        return try! JSONSerialization.data(withJSONObject:
            [
                "items": [
                    ["id": UUID().uuidString, "image": "http://image.com"],
                    ["id": UUID().uuidString, "image": "http://image.com"]
                ]
            ]
        )
    }
}
