//
//  ImageProgressCell.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 11.03.2023.
//

import UIKit
import Combine

class ImageProgressCell: UITableViewCell {
    
    // MARK: - Properties
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let spinner = UIActivityIndicatorView(style: .medium)
    
    private var viewModel: ImageProgressCellVM?
    private var subscriptions: Set<AnyCancellable> = []
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = progressView
        setupSpinner()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        subscriptions.removeAll()
    }
    
    // MARK: - Setup
    
    func setup(viewModel: ImageProgressCellVM) {
        self.viewModel = viewModel
        setupImage()
        setupAccessoryView()
    }
    
    private func setupSpinner() {
        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setupImage() {
        viewModel?.image
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.contentConfiguration = nil
                self?.spinner.startAnimating()
            },
                          receiveCompletion: { [weak self] _ in
                self?.spinner.stopAnimating()
            })
            .sink { [weak self] in
                guard let self else { return }
                spinner.stopAnimating()
                var configuration = defaultContentConfiguration()
                configuration.image = $0
                configuration.imageProperties.cornerRadius = 5
                contentConfiguration = configuration
            }
            .store(in: &subscriptions)
    }
    
    private func setupAccessoryView() {
        viewModel?.$progress
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.progressView.isHidden = true
            })
            .sink { [progressView] progress in
                if let progress {
                    progressView.progress = progress
                    progressView.isHidden = false
                } else {
                    progressView.isHidden = true
                }
            }
            .store(in: &subscriptions)
    }
}
