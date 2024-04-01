//
// Created on 24/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        
        guard let cell = dequeueReusableCell(withIdentifier: identifier) as? T else {
            fatalError("Cell with identifier \(identifier) not found. Make sure the identifier name matches the class name in the storyboard configuration.")
        }
        
        return cell
    }
}
