//
//  ViewController.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 13.02.2023.
//

import UIKit
import Firebase
import CombineFirebase
import Combine
import CombineCocoa

class MainVC: UIViewController {
    
    // MARK: - @IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var threadsCountLabel: UILabel!
    @IBOutlet weak var statisticView: StatisticView!
    @IBOutlet weak var stackView: UIStackView!
    
    // MARK: - Properties
    
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var subscriptions = Set<AnyCancellable>()
    
    var viewModel: MainVM!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupBarButtons()
        setupSpinner()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DebugPrinter.printAppear(for: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DebugPrinter.printDisappear(for: self)
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ImageProgressCell.self, forCellReuseIdentifier: "ImageProgressCell")
        tableView.allowsSelection = false
    }
    
    private func setupBarButtons() {
        setupLeftBarButton()
        setupRightBarButton()
    }
    
    private func setupLeftBarButton() {
        let refreshBarButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: nil)
        viewModel.bindRefreshBarButtonAction(refreshBarButton.tapPublisher)
        navigationItem.leftBarButtonItem = refreshBarButton
    }
    
    private func setupRightBarButton() {
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
        viewModel.bindAddBarButtonAction(addBarButton.tapPublisher)
        viewModel.$addButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: addBarButton)
            .store(in: &subscriptions)
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    private func setupSpinner() {
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - ViewModel Binding
    
    private func bindViewModel() {
        bindViewModelInput()
        bindViewModelOutput()
    }
    
    private func bindViewModelInput() {
        viewModel.bindSliderAction(slider.valuePublisher)
        viewModel.bindMainButtonAction(button.tapPublisher)
    }
    
    private func bindViewModelOutput() {
        bindTitleUpdates()
        bindMainButtonUpdates()
        bindSliderUpdates()
        bindThreadsCountLabelUpdates()
        bindStatisticViewUpdates()
        bindLoaderUpdates()
        bindTableViewUpdates()
    }
    
    private func bindTitleUpdates() {
        viewModel.$title
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in self?.title = title }
            .store(in: &subscriptions)
    }
    
    private func bindMainButtonUpdates() {
        viewModel.$mainButtonState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .enabled(title: let title):
                    self?.button.setTitle(title, for: .normal)
                    self?.button.isEnabled = true
                case .disabled(title: let title):
                    self?.button.setTitle(title, for: .disabled)
                    self?.button.isEnabled = false
                }
            }.store(in: &subscriptions)
    }
    
    private func bindSliderUpdates() {
        viewModel.$sliderEnabled
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: slider)
            .store(in: &subscriptions)
    }
    
    private func bindThreadsCountLabelUpdates() {
        viewModel.$threadsCount
            .removeDuplicates()
            .map { String($0) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: threadsCountLabel)
            .store(in: &subscriptions)
    }
    
    private func bindStatisticViewUpdates() {
        viewModel.$statisticVisibleState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statisticVisibleState in
                guard let self = self else { return }
                switch statisticVisibleState {
                case .hidden: self.statisticView.hideAnimated(in: self.stackView)
                case .shown(let viewModel):
                    self.statisticView.setup(with: viewModel)
                    self.statisticView.showAnimated(in: self.stackView)
                }
            }.store(in: &subscriptions)
    }
    
    private func bindLoaderUpdates() {
        viewModel.$showLoader
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showLoader in
                if showLoader {
                    self?.spinner.startAnimating()
                } else {
                    self?.spinner.stopAnimating()
                }
            }.store(in: &subscriptions)
    }
    
    private func bindTableViewUpdates() {
        viewModel.$changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] changes in
                guard let self = self else { return }
                self.tableView.performBatchUpdates {
                    self.tableView.insertRows(at: changes.inserted, with: .bottom)
                    self.tableView.deleteRows(at: changes.removed, with: .top)
                    self.tableView.reloadRows(at: changes.updated, with: .none)
                }
            }.store(in: &subscriptions)
    }
}

//MARK: - UITableViewDataSource

extension MainVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageProgressCell", for: indexPath)
        guard let cell = cell as? ImageProgressCell,
              let cellVM = viewModel.getItem(for: indexPath.row) else { return cell }
        cell.setup(viewModel: cellVM)
        return cell
    }
}

//MARK: - UITableViewDelegate

extension MainVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.canEdit else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: { [weak self] action, view, success in
            guard let self = self else {
                success(false)
                return
            }
            let successfully = self.viewModel.deleteRow(at: indexPath.row)
            success(successfully)
        })
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ImageProgressCell else { return }
        cell.viewModel = nil
    }
}
