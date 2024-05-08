//
// Created on 06/05/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import UIKit
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let remoteURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        
        let remoteClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let remoteFeedLoader = RemoteFeedLoader(client: remoteClient, url: remoteURL)
        let remoteImageLoader = RemoteFeedImageDataLoader(client: remoteClient)
                
        window?.rootViewController = FeedUIComposer.feedComposedWith(
            loader: remoteFeedLoader,
            imageLoader: remoteImageLoader)

    }
}

