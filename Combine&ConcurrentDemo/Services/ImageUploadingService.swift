//
//  UploadingService.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 26.03.2023.
//

import Foundation
import Combine
import Firebase
import CombineFirebase

enum UploadSource {
    case data(Data)
    case path(Path)
}

// MARK: - UploadingServiceType

protocol UploadingServiceType {
    func upload(from sources: [UploadSource], threadsCount: Int) -> AnyPublisher<(Int, StorageTaskSnapshot), any Error>
}

// MARK: - UploadingServiceType Implementation

final class UploadingService: UploadingServiceType {
    
    func upload(from sources: [UploadSource], threadsCount: Int) -> AnyPublisher<(Int, StorageTaskSnapshot), any Error> {
        let remotePath = Path(filePath: "\(Date.now)").appending(component: "\(UUID().uuidString).png")
        return sources.enumerated().publisher
            .flatMap(maxPublishers: .max(threadsCount)) { index, source in
                FirebaseManager.shared.upload(from: source, to: remotePath)
                    .map { (index, $0) }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}
