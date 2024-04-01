//
// Created on 10/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        
import UIKit

class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing: Bool = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}
