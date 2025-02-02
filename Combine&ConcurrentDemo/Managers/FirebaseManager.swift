//
//  FirebaseManager.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 26.03.2023.
//

import Foundation
import FirebaseStorage
import Combine

final class FirebaseManager {
    
    // MARK: - Singletone
    
    static let shared = FirebaseManager()
    private init() {}
    
    // MARK: - Properties
    
    private let storageReference = Storage.storage().reference()
    
    // MARK: - Methods
    
    func upload(from source: UploadSource,
                metadata: StorageMetadata? = nil,
                to storagePath: Path) -> AnyPublisher<StorageTaskSnapshot, any Error> {
        let fileStorageReference = storagePath.pathComponents.reduce(storageReference) { $0.child($1) }
        switch source {
        case .data(let data):
            return fileStorageReference.putData(data, metadata: metadata).publisher
        case .path(let filePath):
            return fileStorageReference.putFile(from: filePath, metadata: metadata).publisher
        }
    }
}

extension StorageUploadTask {
    
    var publisher: AnyPublisher<StorageTaskSnapshot, any Error> {
        let uploadingPublisher = PassthroughSubject<StorageTaskSnapshot, any Error>()
        
        observe(.progress) {
            uploadingPublisher.send($0)
        }
        observe(.success) {
            uploadingPublisher.send($0)
            uploadingPublisher.send(completion: .finished)
        }
        observe(.failure) {
            uploadingPublisher.send($0)
            uploadingPublisher.send(completion: .failure($0.error ?? AppError.unknown))
        }
        
        return uploadingPublisher.eraseToAnyPublisher()
    }
}
