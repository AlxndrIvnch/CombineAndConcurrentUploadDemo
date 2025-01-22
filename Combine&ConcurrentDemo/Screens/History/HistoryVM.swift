//
//  HistoryVM.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation
import Combine

class HistoryVM: ObservableObject {
    
    // MARK: - Properties
    
    private let coordiantor: HistoryCoordinatorType
    private let updateSubject = PassthroughSubject<Void, Never>()
    
    @Published private var testsInfo: [TestInfo] = []
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Init/Deinit
    
    init(coordiantor: HistoryCoordinatorType) {
        self.coordiantor = coordiantor
        bind()
        DebugPrinter.printInit(for: self)
    }
    
    deinit {
        DebugPrinter.printDeinit(for: self)
    }
    
    // MARK: - Binding
    
    private func bind() {
        bindTestsInfo()
        bindCoreDataUpdates()
    }
    
    private func bindTestsInfo() {
        $testsInfo
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateSubject.send() }
            .store(in: &subscriptions)
    }
    
    private func bindCoreDataUpdates() {
        CoreDataManager.saveObjectsPublisher(for: TestInfo.self, changeTypes: [.inserted])
            .sink { [weak self] in self?.updateTestsInfo(from: $0) }
            .store(in: &subscriptions)
    }
    
    // MARK: - Helper Methods
    
    private func updateTestsInfo(from dictionary: [ChangeType : [TestInfo]]) {
        dictionary.forEach { changeType, changedTestsInfo in
            switch changeType {
            case .inserted: testsInfo.insert(contentsOf: changedTestsInfo, at: .zero)
            default: fatalError("Not implemented")
            }
        }
    }
}

// MARK: - Interanl

extension HistoryVM {
    
    // MARK: - Getters
    
    var updatePublisher: AnyPublisher<Void, Never> { updateSubject.share().eraseToAnyPublisher() }
    
    var itemsCount: Int { testsInfo.count }
    
    func getItem(for index: Int) -> TableViewCellVM? {
        guard testsInfo.indices.contains(index) else { return nil }
        let testInfo = testsInfo[index]
        return .init(title: testInfo.foulderName,
                     subtitle: "Uploaded \(testInfo.imagesCount) images in \(testInfo.time.time.formatedString) using \(testInfo.threadsCount) threads")
    }
    
    // MARK: - Actions
    
    func loadInfo() {
        do {
            testsInfo = try CoreDataManager.getTestsInfo()
        } catch {
            AlertManager.showAlert(message: error.localizedDescription)
        }
    }
    
    // MARK: - Binding
    
    func bindRowSelectionAction(_ publisher: AnyPublisher<IndexPath, Never>) {
        publisher
            .filter { [weak self] in self?.testsInfo.indices.contains($0.row) ?? false }
            .compactMap { [weak self] in self?.testsInfo[$0.row] }
            .map { $0.images }
            .sink { [weak self] images in self?.coordiantor.showImagesGreed(with: images) }
            .store(in: &subscriptions)
    }
}
