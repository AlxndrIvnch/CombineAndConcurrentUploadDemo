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
    private init() {}
    
    // MARK: - Methods
    
    func loadImages(from itemProviders: [NSItemProvider]) -> AnyPublisher<[UIImage], Error> {
        Future { promise in
            autoreleasepool {
                var images = [UIImage]()
                let dispathGroup = DispatchGroup()
                
                for itemProvider in itemProviders where itemProvider.canLoadObject(ofClass: UIImage.self) {

                    dispathGroup.enter()
                    itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage, error == nil {
                            images.append(image)
                            dispathGroup.leave()
                        } else if let error = error {
                            promise(.failure(error))
                        }
                    }
                }

                dispathGroup.notify(queue: .main) {
                    promise(.success(images))
                }
            }
        }.eraseToAnyPublisher()
    }
}
