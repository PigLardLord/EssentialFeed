//
// Created on 10/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        
import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulateEvent(UIControl.Event.valueChanged)
    }
}
