//
//  ValidTestInfo.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import UIKit.UIApplication

struct ValidTestInfo {
    
    // MARK: - Properties
    
    let foulderName: String
    let threadsCount: Int16
    let time: Double
    let images: [URL]
    
    // MARK: - Init
    
    init?(foulderName: String, threadsCount: Int, time: Double, images: [URL]) {
        guard ValidTestInfo.isValidInput(foulderName: foulderName, threadsCount: threadsCount, time: time, images: images) else { return nil }
        self.time = time
        self.foulderName = foulderName
        self.images = images
        self.threadsCount = Int16(threadsCount)
    }
    
    // MARK: - Validation
    
    private static func isValidInput(foulderName: String, threadsCount: Int, time: Double, images: [URL]) -> Bool {
        threadsCount.isPositive &&
        time.isGreaterThanOrEqualTo(.zero) &&
        !foulderName.isEmpty &&
        !images.isEmpty &&
        !images.map({ UIApplication.shared.canOpenURL($0) }).contains { !$0 }
    }
}
