//
//  TableViewCellVM.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation
import UIKit

struct TableViewCellVM {
    
    // MARK: - Properties
    
    let title: String?
    let subtitle: String?
    let image: UIImage?
    
    // MARK: - Init
    
    init(title: String? = nil, subtitle: String? = nil, imageName: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        if let imageName = imageName {
            self.image = .init(named: imageName)
        } else {
            self.image = nil
        }
    }
}
