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
    
    var hasUploaded: Bool { snapshot?.status == .success }
    
    private(set) var snapshot: StorageTaskSnapshot?
    
    // MARK: - Init
    
    init(image: UIImage, snapshot: StorageTaskSnapshot? = nil) {
        self.image = image
        self.snapshot = snapshot
    }
    
    func update(with snapshot: StorageTaskSnapshot?) {
        self.snapshot = snapshot
        if let progress = snapshot?.progress {
            self.progress = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
        } else {
            self.progress = nil
        }
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
