//
// Created on 10/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        
import UIKit

extension UIControl {
    func simulateEvent(_ event: UIControl.Event) {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: event)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        })
    }
}
