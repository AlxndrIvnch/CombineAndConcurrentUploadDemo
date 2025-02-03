//
//  AssetsManager.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 27.03.2023.
//

import Combine
import PhotosUI

final class AssetsManager {
    
    // MARK: - Singletone
    
    static let shared = AssetsManager()
    
    private let cachingImageManager = PHCachingImageManager()
    
    private var subscriptions = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Methods
    
    func loadImages(from itemProviders: [NSItemProvider]) -> AnyPublisher<[UIImage], any Error> {
        itemProviders.enumerated().publisher
            .filter { $1.canLoadObject(ofClass: UIImage.self) }
            .flatMap { index, itemProvider in
                Future { promise in
                    itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            promise(.success((index, image)))
                        } else {
                            promise(.failure(error ?? AppError.unknown))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .collect()
            .map { $0.sorted { $0.0 < $1.0 }.map(\.1) }
            .eraseToAnyPublisher()
    }
    
    func fetchAssets(for assetIdentifiers: [String]) -> AnyPublisher<[PHAsset], Never> {
        return Future { promise in
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
            let assets = fetchResult.objects(at: .init(integersIn: 0..<fetchResult.count))
            promise(.success(assets))
        }
        .eraseToAnyPublisher()
    }
    
    func loadImage(
        for asset: PHAsset,
        parameters: PHImageRequestParameters = .init()
    ) -> AnyPublisher<UIImage?, Never> {
        return loadImages(for: [asset], parameters: parameters)
            .map { $0.isEmpty ? nil : $0[0] }
            .eraseToAnyPublisher()
    }
    
    func loadImages(
        for assets: [PHAsset],
        parameters: PHImageRequestParameters = .init()
    ) -> AnyPublisher<[UIImage?], Never> {
        assert(!assets.isEmpty)
        let lock = NSLock()
        var requestIDs = [PHImageRequestID]()
        return assets.enumerated().publisher
            .subscribe(on: DispatchQueue.global())
            .handleEvents(receiveCancel: { [cachingImageManager] in
                requestIDs.forEach { cachingImageManager.cancelImageRequest($0) }
            })
            .flatMap { [cachingImageManager] index, asset in
                return Future<(Int, UIImage?), Never> { promise in
                    let requestID = cachingImageManager.requestImage(
                        for: asset,
                        targetSize: parameters.targetSize,
                        contentMode: parameters.contentMode,
                        options: parameters.options
                    ) { image, _ in
                        promise(.success((index, image)))
                    }
                    lock.lock()
                    requestIDs.append(requestID)
                    lock.unlock()
                }
                .receive(on: DispatchQueue.global())
                .eraseToAnyPublisher()
            }
            .collect()
            .map { $0.sorted { $0.0 < $1.0 }.map { $0.1 } }
            .eraseToAnyPublisher()
    }
    
    func startCachingImages(
        for assets: PHAsset...,
        parameters: PHImageRequestParameters = .init()
    ) {
        cachingImageManager.startCachingImages(for: assets,
                                               targetSize: parameters.targetSize,
                                               contentMode: parameters.contentMode,
                                               options: parameters.options)
    }
    
    func stopCachingImages(
        for assets: PHAsset...,
        parameters: PHImageRequestParameters = .init()
    ) {
        cachingImageManager.stopCachingImages(for: assets,
                                              targetSize: parameters.targetSize,
                                              contentMode: parameters.contentMode,
                                              options: parameters.options)
    }
    
    func stopCachingImagesForAllAssets() {
        cachingImageManager.stopCachingImagesForAllAssets()
    }
}

extension AssetsManager {
    
    struct PHImageRequestParameters {
        let targetSize: CGSize
        let contentMode: PHImageContentMode
        let options: PHImageRequestOptions?
        
        init(targetSize: CGSize = PHImageManagerMaximumSize,
             contentMode: PHImageContentMode = .aspectFit,
             options: PHImageRequestOptions? = nil) {
            self.targetSize = targetSize
            self.contentMode = contentMode
            self.options = options
        }
    }
}
