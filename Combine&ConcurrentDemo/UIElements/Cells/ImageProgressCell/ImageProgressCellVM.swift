//
//  ImageProgressCellVM.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 12.03.2023.
//

import Combine
import CombineFirebase
import Firebase
import UIKit.UIImage

struct ImageProgressCellVM: Hashable {
    
    // MARK: - Properties
    
    let image: UIImage
    let progress: Float?
    
    // MARK: - Init
    
    init(image: UIImage, snapshot: StorageTaskSnapshot? = nil) {
        self.image = image
        if let progress = snapshot?.progress {
            self.progress = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
        } else {
            self.progress = nil
        }
    }
}
