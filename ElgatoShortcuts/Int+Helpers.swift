//
//  Int+Helpers.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation

extension Int {
    func between(min: Int, max: Int) -> Int {
        Swift.max(Swift.min(self, max), min)
    }
}
