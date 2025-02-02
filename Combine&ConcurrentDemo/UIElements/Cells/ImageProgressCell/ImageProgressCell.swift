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
    
    private var viewModel: ImageProgressCellVM?
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = progressView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        cancellables.removeAll()
    }
    
    // MARK: - Setup
    
    func setup(viewModel: ImageProgressCellVM) {
        self.viewModel = viewModel
        setupImage()
        setupAccessoryView()
    }
    
    private func setupImage() {
        var configuration = defaultContentConfiguration()
        configuration.image = viewModel?.image
        configuration.imageProperties.cornerRadius = 5
        contentConfiguration = configuration
    }
    
    private func setupAccessoryView() {
        viewModel?.$progress
            .receive(on: DispatchQueue.main)
            .sink { [progressView] progress in
                if let progress {
                    progressView.progress = progress
                    progressView.isHidden = false
                } else {
                    progressView.isHidden = true
                }
            }
            .store(in: &cancellables)
       
    }
}
