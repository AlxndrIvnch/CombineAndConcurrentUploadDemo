//
//  MainVM.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 26.03.2023.
//

import Foundation
import PhotosUI
import Firebase
import CombineFirebase
import Combine

final class MainVM: ObservableObject {
    
    // MARK: - State
    
    enum State {
        case setup
        case ready
        case inProgress
        case finished(error: Error? = nil)
    }
    
    // MARK: - Private(set) Properties
    
    @Published private(set) var threadsCount: Int = 1
    @Published private(set) var addButtonEnabled = true
    @Published private(set) var mainButtonState: ButtonState = .disabled(title: "Start")
    @Published private(set) var sliderEnabled = true
    @Published private(set) var showLoader = false
    @Published private(set) var statisticVisibleState: VisibilityState<StatisticVM> = .hidden
    @Published private(set) var changes: Changes = .none
    @Published private(set) var title: String = "Upload images"
    
    // MARK: - Private Properties
    
    private let uploadingService: UploadingServiceType = UploadingService()
    private let timerPublisher = Timer.publish(every: 0.011, on: .main, in: .common).autoconnect()
    
    @Published private var items: [ImageProgressCellVM] = []
    @Published private var images: [UIImage] = []
    @Published private var snapshots: [StorageTaskSnapshot?] = []
    @Published private var state: State = .setup
    @Published private var time: Double?
    
    private var subscriptions = Set<AnyCancellable>()
    private var uploadSubscriptions = Set<AnyCancellable>()
    
    // MARK: - Init/Deinit
    
    init() {
        bind()
        DebugPrinter.printInit(for: self)
    }
    
    deinit {
        DebugPrinter.printDeinit(for: self)
    }
    
    // MARK: - Binding
    
    private func bind() {
        bindState()
        bindImages()
        bindItemsUpdates()
        bindChangesUpdates()
        bindTime()
    }
    private func bindItemsUpdates() {
        $images
            .map { $0.map(ImageProgressCellVM.init) }
            .sink { [weak self] in self?.items = $0 }
            .store(in: &subscriptions)
    }
    
    private func bindChangesUpdates() {
        $items
            .scan(([], [])) { ($0.1, $1) }
            .map { (old, new) -> Changes in .init(new: new, old: old) }
            .sink { [weak self] changes in self?.changes = changes }
            .store(in: &subscriptions)
    }
    
    private func bindImages() {
        $images
            .map(\.count)
            .filter(\.isPositive)
            .sink { [weak self] imagesCount in self?.title = "Upload images (\(imagesCount))" }
            .store(in: &subscriptions)
    }
    
    private func bindTime() {
        $time
            .compactMap { [weak self] time -> StatisticVM? in
                guard let self = self, let time = time else { return nil }
                let uploaded = self.snapshots.filter({ $0?.status == .success })
                return StatisticVM(time: time, allCount: self.snapshots.count, uploadedCount: uploaded.count)
            }
            .sink { [weak self] in
                guard let self = self, case .inProgress = self.state else { return }
                self.statisticVisibleState = .shown($0)
            }.store(in: &subscriptions)
    }
    
    private func bindState() {
        $state
            .print()
            .sink { [weak self] in self?.updateState($0) }
            .store(in: &subscriptions)
    }
    
    // MARK: - Timer Handling
    
    private func startTimer() {
        let start = Date.now
        timerPublisher
            .map { $0.timeIntervalSince(start) }
            .sink { [weak self] in self?.time = $0 }
            .store(in: &subscriptions)
    }
    
    private func stopTimer() {
        timerPublisher.upstream.connect().cancel()
    }
    
    // MARK: - Helper Methods
    
    private func saveOnDisk(data: Data, fileName: String =  UUID().uuidString) -> AnyPublisher<Path, any Error> {
        Future { promise in
            DispatchQueue.global(qos: .utility).async {
                let imagePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try data.write(to: imagePath)
                    promise(.success(imagePath))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func showFinishAlert(for error: Error?) -> AnyPublisher<AlertManager.AlertAction, Never>? {
        if let error = error {
            return AlertManager.showAlert(message: error.localizedDescription)
        } else {
            return AlertManager.showAlert(message: "Successfully uploaded \(images.count) image(s) in \(time?.time.formatedString ?? "") seconds")
        }
    }
    
    private func downloadURLsAndSaveInfoToCoreData() {
        downloadURLs()
             .compactMap { [weak self] in self?.createModelIfPossible(with: $0) }
             .sink { completion in
                 if case .failure(let error) = completion {
                     AlertManager.showAlert(message: error.localizedDescription)
                 }
             } receiveValue: { [weak self] in self?.saveToCoreData($0) }
            .store(in: &subscriptions)
    }
    
    //MARK: - State Changes Handling
    
    private func updateState(_ state: State) {
        switch state {
        case .setup: onSetup()
        case .ready: onReady()
        case .inProgress: onInProgress()
        case .finished(error: let error): onFinished(with: error)
        }
    }
    
    private func onSetup() {
        cancelUploading()
        addButtonEnabled = true
        mainButtonState = .disabled(title: "Start")
        sliderEnabled = true
        statisticVisibleState = .hidden
        stopTimer()
        snapshots.removeAll()
        images.removeAll()
    }
    
    private func onReady() {
        cancelUploading()
        addButtonEnabled = true
        mainButtonState = .enabled(title: "Start")
        sliderEnabled = true
        statisticVisibleState = .hidden
        stopTimer()
        snapshots = .init(repeating: nil, count: images.count)
    }
    
    private func onInProgress() {
        addButtonEnabled = false
        mainButtonState = .enabled(title: "Stop")
        sliderEnabled = false
        startTimer()
        uploadImages()
    }
    
    private func onFinished(with error: Error? = nil) {
        if error == nil {
            downloadURLsAndSaveInfoToCoreData()
        }
        addButtonEnabled = false
        mainButtonState = .enabled(title: "Start")
        sliderEnabled = false
        stopTimer()
        statisticVisibleState = .hidden
        showFinishAlert(for: error)?
            .sink { [weak self] _ in self?.state = .ready }
            .store(in: &subscriptions)
    }
    
    // MARK: - Images Picking
    
    private func createPickerConfiguration() -> PHPickerConfiguration {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selection = .default
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = 0
        return configuration
    }
    
    private func pickImages() {
        let configuration = createPickerConfiguration()
        PHPickerManager.shared.showPHPicker(with: configuration)
            .map { $0.map(\.itemProvider) }
            .handleEvents(receiveOutput: { [weak self] _ in self?.showLoader = true })
            .flatMap(maxPublishers: .max(1)) { AssetsManager.shared.loadImages(from: $0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.showLoader = false
                if case .failure(let error) = completion {
                    AlertManager.showAlert(message: error.localizedDescription)
                }
            } receiveValue: { [weak self] images in
                self?.images.append(contentsOf: images)
                self?.state = .ready
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Networking
    
    private func uploadImages() {
        images.publisher
            .flatMap { [unowned self] image -> AnyPublisher<UploadSource, any Error> in
                guard let data = image.pngData() else {
                    return Fail(error: AppError.pngDataTransformationFailed)
                        .eraseToAnyPublisher()
                }
                if true {
                    return saveOnDisk(data: data)
                        .map { .path($0) }
                        .eraseToAnyPublisher()
                } else {
                    return Just(.data(data))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .collect()
            .flatMap { [unowned self] in
                uploadingService.upload(from: $0, threadsCount: threadsCount)
            }
            .sink { [unowned self] completion in
                switch completion {
                case .finished: state = .finished()
                case .failure(let error): state = .finished(error: error)
                }
            } receiveValue: { [unowned self] index, snapshot in
                items[index].updateProgress(from: snapshot)
            }
            .store(in: &uploadSubscriptions)
    }
    
    private func cancelUploading() {
        uploadSubscriptions.removeAll()
    }
    
    private func downloadURLs() -> AnyPublisher<[URL], Error> {
        snapshots.publisher
            .compactMap { $0 }
            .flatMap(maxPublishers: .max(1)) { $0.reference.downloadURL() }
            .collect()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Core Data
    
    private func saveToCoreData(_ validTestInfo: ValidTestInfo) {
        do {
            try CoreDataManager.saveTestInfo(validTestInfo)
        } catch {
            AlertManager.showAlert(message: error.localizedDescription)
        }
    }
    
    private func createModelIfPossible(with urls: [URL]) -> ValidTestInfo? {
        guard let time = time,
              let folderName = snapshots.compactMap({ $0 }).first?.reference.parent()?.name else { return nil }
        return ValidTestInfo(folderName: folderName, threadsCount: threadsCount, time: time, images: urls)
    }
}

// MARK: - Interanl

extension MainVM {
    
    // MARK: - Getters
    
    var canEdit: Bool { state == .setup || state == .ready }
    
    var itemsCount: Int { items.count }
    
    func getItem(for index: Int) -> ImageProgressCellVM? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }
    
    // MARK: - Actions
    
    @discardableResult func deleteRow(at index: Int) -> Bool {
        guard images.indices.contains(index) else { return false }
        images.remove(at: index)
        state = images.isEmpty ? .setup : .ready
        return true
    }
    
    // MARK: - Binding
    
    func bindRefreshBarButtonAction(_ publisher: AnyPublisher<Void, Never>) {
        publisher
            .sink { [weak self] _ in self?.state = .setup }
            .store(in: &subscriptions)
    }
    
    func bindAddBarButtonAction(_ publisher: AnyPublisher<Void, Never>) {
        publisher
            .sink { [weak self] _ in self?.pickImages() }
            .store(in: &subscriptions)
    }
    
    func bindMainButtonAction(_ publisher: AnyPublisher<Void, Never>) {
        publisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                switch self.state {
                case .ready: self.state = .inProgress
                case .inProgress: self.state = .ready
                default: break
                }
            }.store(in: &subscriptions)
    }
    
    func bindSliderAction(_ publisher: AnyPublisher<Float, Never>) {
        publisher
            .map { Int($0) }
            .removeDuplicates()
            .sink { [weak self] in self?.threadsCount = $0 }
            .store(in: &subscriptions)
    }
}

//MARK: - State: Equatable

extension MainVM.State: Equatable {
    static func == (lhs: MainVM.State, rhs: MainVM.State) -> Bool {
        switch (lhs, rhs) {
        case (.setup, .setup): return true
        case (.ready, .ready): return true
        case (.inProgress, .inProgress): return true
        case let (.finished(error1), .finished(error2)): return error1?.localizedDescription == error2?.localizedDescription
        default: return false
        }
    }
}
