//
//  ButtonState.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

enum ButtonState: Equatable {
    case enabled(title: String)
    case disabled(title: String)
}
