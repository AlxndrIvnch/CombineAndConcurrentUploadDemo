//
//  Sequence.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

extension Sequence {
    func replacingAll<T>(with value: T) -> [T] { self.map { _ in value } }
    func replacingAllWithNil<T>() -> [T?] { self.replacingAll(with: nil) }
}

extension Sequence where Element == Int {
    func createIndexPaths(for section: Int = 0) -> [IndexPath] {
        return self.map { IndexPath(item: $0, section: section) }
    }
    
    func createSectionIndexPaths() -> [IndexPath] {
        return self.map { IndexPath(item: 0, section: $0) }
    }
}
