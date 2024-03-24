//
// Created on 24/03/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import Foundation
import XCTest
import EssentialFeediOS

extension FeedViewControllerTests {
    func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
        let table = "Feed"
        let bundle = Bundle(for: FeedViewController.self)
        let value = bundle.localizedString(forKey: key , value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key)", file: file, line: line)
        }
        return value
    }
}
