//
//  PHPickerManager.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 26.03.2023.
//

import PhotosUI
import Combine

final class PHPickerManager {
    
    // MARK: - Singletone
    
    static let shared = PHPickerManager()
    private init() {}
    
    // MARK: - Properties
    
    private var publisher: PassthroughSubject<[PHPickerResult], Never>?
    
    // MARK: - Methods
    
    func showPHPicker(with configuration: PHPickerConfiguration = .init()) -> AnyPublisher<[PHPickerResult], Never> {
        let picker = createPHPicker(configuration: configuration)
        let publisher = PassthroughSubject<[PHPickerResult], Never>()
        self.publisher = publisher
        if let vc = UIViewController.topViewController {
            vc.present(picker, animated: true)
        } else {
            publisher.send(completion: .finished)
        }
        return publisher.eraseToAnyPublisher()
    }
    
    private func createPHPicker(configuration: PHPickerConfiguration) -> PHPickerViewController {
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        return picker
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PHPickerManager: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if !results.isEmpty {
            publisher?.send(results)
        }
        publisher?.send(completion: .finished)
        picker.dismiss(animated: true)
    }
}
