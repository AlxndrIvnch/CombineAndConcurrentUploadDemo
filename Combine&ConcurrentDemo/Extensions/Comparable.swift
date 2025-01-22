//
//  Comparable.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

extension Comparable {
    func isEqual(to other: Self) -> Bool { self == other }
    func isNotEqual(to other: Self) -> Bool { self != other }
    
    func isGreater(than other: Self) -> Bool { self > other }
    func isGreaterThanOrEqualTo(_ other: Self) -> Bool { self.isGreater(than: other) || self.isEqual(to: other) }
    
    func isLess(than other: Self) -> Bool { self < other }
    func isLessThanOrEqualTo(_ other: Self) -> Bool { self.isLess(than: other) || self.isEqual(to: other) }
}

extension Comparable where Self: Numeric {
    var isPositive: Bool { self.isGreater(than: .zero) }
    var isNegative: Bool { self.isLess(than: .zero) }
}
