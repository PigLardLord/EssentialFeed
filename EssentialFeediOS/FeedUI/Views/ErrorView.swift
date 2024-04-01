//
// Created on 01/04/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import UIKit

public final class ErrorView: UIView {
    @IBOutlet private(set) public var button: UIButton!

    public var message: String? {
        get { return isVisible ? button.title(for: .normal) : nil }
        set { setMessageAnimated(newValue) }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        button.setTitle(nil, for: .normal)
        alpha = 0
    }
    
    private var isVisible: Bool {
        return alpha > 0
    }
    
    private func setMessageAnimated(_ message: String?) {
        if let message = message {
            show(message)
        } else {
            hideMessage()
        }
    }
    
    private func show(_ message: String) {
        button.setTitle(message, for: .normal)
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }

    @IBAction func hideMessage() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = 0 },
            completion: { completed in
                if completed {
                    self.button.setTitle(nil, for: .normal)
                }
            }
        )
    }
}
