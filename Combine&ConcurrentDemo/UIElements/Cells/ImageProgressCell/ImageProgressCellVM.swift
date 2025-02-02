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

final class ImageProgressCellVM: ObservableObject {
    
    // MARK: - Properties
    
    let image: UIImage
    @Published private(set) var progress: Float?
    
    // MARK: - Init
    
    init(image: UIImage) {
        self.image = image
    }
    
    func updateProgress(from snapshot: StorageTaskSnapshot) {
        guard let progress = snapshot.progress else { return }
        self.progress = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
    }
}

extension ImageProgressCellVM: Hashable {
    
    static func == (lhs: ImageProgressCellVM, rhs: ImageProgressCellVM) -> Bool {
        lhs.image == rhs.image
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(image)
    }
}
