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
        case start
        case finished(error: Error? = nil)
    }
    
    // MARK: - Private(set) Properties
    
    @Published private(set) var threadsCount = 1
    @Published private(set) var addButtonEnabled = true
    @Published private(set) var mainButtonState: ButtonState = .disabled(title: "Start")
    @Published private(set) var sliderEnabled = true
    @Published private(set) var showLoader = false
    @Published private(set) var statisticVisibleState: VisibilityState<StatisticVM> = .hidden
    @Published private(set) var changes: Changes = .none
    @Published private(set) var title = "Upload images"
    
    // MARK: - Private Properties
    
    private let uploadingService: UploadingServiceType
    private let timerPublisher = Timer.publish(every: 0.011, on: .main, in: .common).autoconnect()
    
    @Published private var items: [ImageProgressCellVM] = []
    @Published private var state: State = .setup
    @Published private var time: Double?
    
    private var subscriptions = Set<AnyCancellable>()
    private var uploadSubscriptions = Set<AnyCancellable>()
    
    // MARK: - Init/Deinit
    
    init(uploadingService: UploadingServiceType = UploadingService()) {
        self.uploadingService = uploadingService
        bind()
        DebugPrinter.printInit(for: self)
    }
    
    deinit {
        DebugPrinter.printDeinit(for: self)
    }
    
    // MARK: - Binding
    
    private func bind() {
        bindState()
        bindItems()
        bindTime()
    }
    
    private func bindItems() {
        Publishers.Zip($items, $items.dropFirst(1))
            .map { old, new in Changes(new: new, old: old) }
            .assign(to: &$changes)
        
        $items
            .map(\.count)
            .map { "Upload images" + ($0 > 0 ? " (\($0))" : "") }
            .assign(to: &$title)
    }
    
    private func bindTime() {
        $time
            .map { [unowned self] time in
                guard let time else { return .hidden }
                let statisticVM =  StatisticVM(time: time,
                                               allCount: items.count,
                                               uploadedCount: items.filter(\.hasUploaded).count)
                return .shown(statisticVM)
            }
            .assign(to: &$statisticVisibleState)
    }
    
    private func bindState() {
        $state
            .sink { [unowned self] in
                switch $0 {
                case .setup: onSetup()
                case .ready: onReady()
                case .start: onStart()
                case .finished(error: let error): onFinished(with: error)
                }
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Timer Handling
    
    private func startTimer() {
        let start = Date.now
        timerPublisher
            .map { $0.timeIntervalSince(start) }
            .assign(to: &$time)
    }
    
    private func stopTimer() {
        timerPublisher.upstream.connect().cancel()
    }
    
    // MARK: - Helper Methods
    
    private func saveOnDisk(data: Data, fileName: String =  UUID().uuidString) -> AnyPublisher<Path, any Error> {
        Future { promise in
            let imagePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                try data.write(to: imagePath)
                promise(.success(imagePath))
            } catch {
                promise(.failure(error))
            }
        }
        .subscribe(on: DispatchQueue.global())
        .eraseToAnyPublisher()
    }
    
    private func showFinishAlert(for error: Error?) -> AnyPublisher<AlertManager.AlertAction, Never> {
        if let error {
            return AlertManager.showAlert(message: error.localizedDescription)
        } else {
            return AlertManager.showAlert(message: "Successfully uploaded \(items.count) image(s) in \(time?.time.formattedString ?? "") seconds")
        }
    }
    
    private func saveInfoToCoreData() {
        let snapshots = items.compactMap(\.snapshot)
        downloadURLs(from: snapshots)
            .compactMap { [threadsCount, time] urls in
                let folderName = snapshots.first?.reference.parent()?.name ?? "N/A"
                return ValidTestInfo(folderName: folderName,
                                     threadsCount: threadsCount,
                                     time: time ?? 0,
                                     images: urls)
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    AlertManager.showAlert(message: error.localizedDescription)
                }
            } receiveValue: {
                do {
                    try CoreDataManager.saveTestInfo($0)
                } catch {
                    AlertManager.showAlert(message: error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
    
    //MARK: - State Changes Handling
    
    private func onSetup() {
        cancelUploading()
        addButtonEnabled = true
        mainButtonState = .disabled(title: "Start")
        sliderEnabled = true
        statisticVisibleState = .hidden
        stopTimer()
        items.removeAll()
    }
    
    private func onReady() {
        items.forEach { $0.update(with: nil) }
        cancelUploading()
        addButtonEnabled = true
        mainButtonState = .enabled(title: "Start")
        sliderEnabled = true
        statisticVisibleState = .hidden
        stopTimer()
    }
    
    private func onStart() {
        createImageSources()
            .sink { [unowned self] completion in
                if case .failure(let error) = completion {
                    onFinished(with: error)
                }
            } receiveValue: { [unowned self] in
                addButtonEnabled = false
                mainButtonState = .enabled(title: "Stop")
                sliderEnabled = false
                startTimer()
                uploadImages(from: $0)
            }
            .store(in: &subscriptions)
    }
    
    private func onFinished(with error: Error? = nil) {
        stopTimer()
        if error == nil {
            saveInfoToCoreData()
        }
        addButtonEnabled = false
        mainButtonState = .enabled(title: "Start")
        sliderEnabled = false
        statisticVisibleState = .hidden
        showFinishAlert(for: error)
            .map { _ in .ready }
            .assign(to: &$state)
    }
    
    // MARK: - Images Picking
    
    private lazy var pickerConfiguration: PHPickerConfiguration = {
        let photoLibrary = PHPhotoLibrary.shared()
        var configuration = PHPickerConfiguration(photoLibrary: photoLibrary)
        configuration.filter = .images
        configuration.selection = .default
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = 0
        return configuration
    }()
    
    private func pickImages() {
        PHPickerManager.shared.showPHPicker(with: pickerConfiguration)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .handleEvents(receiveOutput: { [weak self] _ in self?.showLoader = true })
            .map { $0.compactMap(\.assetIdentifier) }
            .flatMap { AssetsManager.shared.fetchAssets(for: $0) }
            .handleEvents(receiveCompletion: { [weak self] _ in self?.showLoader = false })
            .sink { completion in
                if case .failure(let error) = completion {
                    AlertManager.showAlert(message: error.localizedDescription)
                }
            } receiveValue: { [weak self] assets in
                self?.items.append(contentsOf: assets.map { ImageProgressCellVM(asset: $0) })
                self?.state = .ready
            }
            .store(in: &subscriptions)
    }
    
    private func createImageSources() -> AnyPublisher<[UploadSource], any Error> {
        items.publisher
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .handleEvents(receiveOutput: { [weak self] _ in self?.showLoader = true })
            .map(\.asset)
            .flatMap {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.resizeMode = .none
                return AssetsManager.shared.loadImage(for: $0, parameters: .init(options: options))
            }
            .flatMap { [unowned self] image -> AnyPublisher<UploadSource, any Error> in
                autoreleasepool {
                    guard let data = image?.pngData() else {
                        return Fail(error: AppError.pngDataTransformationFailed).eraseToAnyPublisher()
                    }
                    if data.count > 3_000_000 { // if image size is more than 3 MB save it on disk
                        return saveOnDisk(data: data)
                            .map { .path($0) }
                            .eraseToAnyPublisher()
                    } else {
                        return Just(.data(data))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                }
            }
            .collect()
            .handleEvents(receiveCompletion: { [weak self] _ in self?.showLoader = false })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Networking
    
    private func uploadImages(from imageSources: [UploadSource]) {
        Just(imageSources)
            .flatMap { [unowned self] in uploadingService.upload(from: $0, threadsCount: threadsCount) }
            .sink { [weak self] completion in
                switch completion {
                case .finished: self?.state = .finished()
                case .failure(let error): self?.state = .finished(error: error)
                }
            } receiveValue: { [weak self] index, snapshot in
                self?.items[index].update(with: snapshot)
            }
            .store(in: &uploadSubscriptions)
    }
    
    private func cancelUploading() {
        uploadSubscriptions.removeAll()
    }
    
    private func downloadURLs(from snapshots: [StorageTaskSnapshot]) -> AnyPublisher<[URL], Error> {
        snapshots.publisher
            .subscribe(on: DispatchQueue.global(qos: .utility))
            .flatMap { $0.reference.downloadURL() }
            .collect()
            .eraseToAnyPublisher()
    }
}

// MARK: - Internal

extension MainVM {
    
    // MARK: - Getters
    
    var canEdit: Bool { [.setup, .ready].contains(state) }
    
    var itemsCount: Int { items.count }
    
    func getItem(for index: Int) -> ImageProgressCellVM? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }
    
    // MARK: - Actions
    
    @discardableResult func deleteRow(at index: Int) -> Bool {
        guard items.indices.contains(index) else { return false }
        items.remove(at: index)
        state = items.isEmpty ? .setup : .ready
        return true
    }
    
    func prefetchRows(at indexPaths: [IndexPath]) {
        indexPaths.map(\.row).forEach {
            guard items.indices.contains($0) else { return }
            items[$0].startCachingImage()
        }
    }
    
    func cancelPrefetchingRows(at indexPaths: [IndexPath]) {
        indexPaths.map(\.row).forEach {
            guard items.indices.contains($0) else { return }
            items[$0].stopCachingImage()
        }
    }
    
    // MARK: - Binding
    
    func bindRefreshBarButtonAction(_ publisher: AnyPublisher<Void, Never>) {
        publisher
            .map { .setup }
            .assign(to: &$state)
    }
    
    func bindAddBarButtonAction(_ publisher: AnyPublisher<Void, Never>) {
        publisher
            .sink { [weak self] in self?.pickImages() }
            .store(in: &subscriptions)
    }
    
    func bindMainButtonAction(_ publisher: AnyPublisher<Void, Never>) {
        publisher
            .compactMap { [weak self] in
                guard let self else { return nil }
                return switch state {
                case .ready: .start
                case .start: .ready
                default: nil
                }
            }
            .assign(to: &$state)
    }
    
    func bindSliderAction(_ publisher: AnyPublisher<Float, Never>) {
        publisher
            .map { Int($0) }
            .removeDuplicates()
            .assign(to: &$threadsCount)
    }
}

//MARK: - State: Equatable

extension MainVM.State: Equatable {
    static func == (lhs: MainVM.State, rhs: MainVM.State) -> Bool {
        return switch (lhs, rhs) {
        case (.setup, .setup): true
        case (.ready, .ready): true
        case (.start, .start): true
        case let (.finished(error1), .finished(error2)): error1?.localizedDescription == error2?.localizedDescription
        default: false
        }
    }
}
