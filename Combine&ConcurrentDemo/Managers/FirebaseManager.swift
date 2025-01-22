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
    
    func uploadFile(with path: Path,
                    metadata: StorageMetadata? = nil,
                    to fouldersPath: [String] = []) -> AnyPublisher<StorageTaskSnapshot, Error> {
        autoreleasepool {
            let lastFoulderReference = fouldersPath.reduce(storageReference) { $0.child($1) }
            let fileReference = lastFoulderReference.child(path.lastPathComponent)
            
            let uploadTask: StorageUploadTask = fileReference.putFile(from: path, metadata: metadata)
            
            let uploadingSubject = PassthroughSubject<StorageTaskSnapshot, Error>()
            
            uploadTask.observe(.progress) { snapshot in
                uploadingSubject.send(snapshot)
            }
            
            uploadTask.observe(.success) { snapshot in
                uploadingSubject.send(snapshot)
                uploadingSubject.send(completion: .finished)
            }
            
            uploadTask.observe(.failure) { snapshot in
                uploadingSubject.send(snapshot)
                uploadingSubject.send(completion: .failure(snapshot.error ?? AppError.unknown))
            }
            
            return uploadingSubject
                .handleEvents(receiveCancel: {
                    uploadTask.removeAllObservers()
                    uploadTask.cancel()
                })
                .eraseToAnyPublisher()
        }
    }
    
    func upload(_ data: Data,
                metadata: StorageMetadata? = nil,
                to fouldersPath: [String] = [],
                fileName: String = UUID().uuidString) -> AnyPublisher<StorageTaskSnapshot, Error> {
        autoreleasepool {
            let lastFoulderReference = fouldersPath.reduce(storageReference) { $0.child($1) }
            let fileReference = lastFoulderReference.child(fileName)
            
            let uploadTask: StorageUploadTask = fileReference.putData(data, metadata: metadata)
            
            let uploadingSubject = PassthroughSubject<StorageTaskSnapshot, Error>()
            
            uploadTask.observe(.progress) { snapshot in
                uploadingSubject.send(snapshot)
            }
            
            uploadTask.observe(.success) { snapshot in
                uploadingSubject.send(snapshot)
                uploadingSubject.send(completion: .finished)
            }
            
            uploadTask.observe(.failure) { snapshot in
                uploadingSubject.send(snapshot)
                uploadingSubject.send(completion: .failure(snapshot.error ?? AppError.unknown))
            }
            
            return uploadingSubject
                .handleEvents(receiveCancel: {
                    uploadTask.removeAllObservers()
                    uploadTask.cancel()
                })
                .eraseToAnyPublisher()
        }
    }
}
