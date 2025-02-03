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
        let removeFolderPath = Path(filePath: "\(Date.now)")
        return sources.enumerated().publisher
            .subscribe(on: DispatchQueue.global())
            .flatMap(maxPublishers: .max(threadsCount)) { index, source in
                let removeFilePath = removeFolderPath.appending(component: "\(UUID().uuidString).png")
                return FirebaseManager.shared.upload(from: source, to: removeFilePath)
                    .map { (index, $0) }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}
