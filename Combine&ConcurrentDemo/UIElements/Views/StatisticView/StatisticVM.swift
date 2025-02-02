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
    
    init(time: TimeInterval, allCount: Int, uploadedCount: Int) {
        self.time = time.time.formattedString
        self.allCount = String(allCount)
        self.uploadedCount = String(uploadedCount)
    }
}
