//
//  VisibilityState.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

enum VisibilityState<T> {
    case hidden
    case shown(T)
}
