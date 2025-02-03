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
import Photos

final class ImageProgressCellVM: ObservableObject {
    
    // MARK: - Properties
    
    let asset: PHAsset
    
    private(set) lazy var image = AssetsManager.shared.loadImage(for: asset,
                                                                 parameters: imageRequestParameters)
    
    @Published private(set) var progress: Float?
    
    var hasUploaded: Bool { snapshot?.status == .success }
    
    private(set) var snapshot: StorageTaskSnapshot?
    
    private let imageRequestParameters: AssetsManager.PHImageRequestParameters = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        return .init(targetSize: .init(width: 300, height: 300),
                     contentMode: .aspectFit,
                     options: options)
    }()
    
    // MARK: - Init
    
    init(asset: PHAsset, snapshot: StorageTaskSnapshot? = nil) {
        self.asset = asset
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
    
    func startCachingImage() {
        AssetsManager.shared.startCachingImages(for: asset, parameters: imageRequestParameters)
    }
    
    func stopCachingImage() {
        AssetsManager.shared.stopCachingImages(for: asset, parameters: imageRequestParameters)
    }
}

extension ImageProgressCellVM: Hashable {
    
    static func == (lhs: ImageProgressCellVM, rhs: ImageProgressCellVM) -> Bool {
        lhs.asset == rhs.asset
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(asset)
    }
}
