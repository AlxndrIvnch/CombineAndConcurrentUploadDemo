//
//  AppError.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

enum AppError: String, Error {
    case unknown
    case pngDataTransformationFailed
    
    var localizedDescription: String? {
        self.rawValue.reduce("", { $0 + ($1.isUppercase ? " \($1)" : "\($1)") }).lowercased().capitalizedSentence
    }
}
