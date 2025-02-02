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
}
