//
//  HistoryTVC.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import UIKit
import Combine
import CombineCocoa

class HistoryTVC: UITableViewController {
    
    // MARK: - Properties
    
    private var subscriptions = Set<AnyCancellable>()
    
    var viewModel: HistoryVM!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "History"
        setupTableView()
        bindViewModel()
        viewModel.loadInfo()
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
        tableView.tableHeaderView = .init()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
    }
    
    // MARK: - ViewModel Binding
    
    private func bindViewModel() {
        bindViewModelInput()
        bindViewModelOutput()
    }
    
    private func bindViewModelInput() {
        viewModel.bindRowSelectionAction(tableView.didSelectRowPublisher)
    }
    
    private func bindViewModelOutput() {
        viewModel.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &subscriptions)
    }
}

// MARK: - Table view data source

extension HistoryTVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemsCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        guard let cell = cell as? TableViewCell,
              let cellVM = viewModel.getItem(for: indexPath.row) else { return cell }
        cell.setup(with: cellVM)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
