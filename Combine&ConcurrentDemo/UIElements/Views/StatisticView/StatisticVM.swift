//
//  StatisticVM.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

struct StatisticVM: Equatable {
    
    // MARK: - Properties
    
    let time: String
    let allCount: String
    let uploadedCount: String
    
    // MARK: - Init
    
    init?(time: TimeInterval, allCount: Int, uploadedCount: Int) {
        guard StatisticVM.isValidInput(time: time, allCount: allCount, uploadedCount: uploadedCount) else { return nil }
        self.time = time.time.formatedString
        self.allCount = String(allCount)
        self.uploadedCount = String(uploadedCount)
    }
    
    // MARK: - Methods
    
    private static func isValidInput(time: Double, allCount: Int, uploadedCount: Int) -> Bool {
        time.isGreaterThanOrEqualTo(0.001) &&
        allCount.isPositive &&
        uploadedCount.isGreaterThanOrEqualTo(.zero) &&
        allCount.isGreaterThanOrEqualTo(uploadedCount)
    }
}
