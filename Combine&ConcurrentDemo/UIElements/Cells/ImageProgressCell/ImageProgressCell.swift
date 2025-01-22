//
//  ImageProgressCell.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 11.03.2023.
//

import UIKit
import Firebase

class ImageProgressCell: UITableViewCell {
    
    // MARK: - Properties
    
    var viewModel: ImageProgressCellVM!
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }
    
    // MARK: - Setup
    
    func setup(viewModel: ImageProgressCellVM) {
        self.viewModel = viewModel
        setupImage()
        setupAccessoryView()
    }
    
    private func setupImage() {
        var configuration = self.defaultContentConfiguration()
        configuration.image = viewModel.image
        configuration.imageProperties.cornerRadius = 5
        self.contentConfiguration = configuration
    }
    
    private func setupAccessoryView() {
        if let progress = viewModel.progress {
            let progressView = UIProgressView(progressViewStyle: .default)
            progressView.progress = progress
            self.accessoryView = progressView
        } else {
            self.accessoryView = nil
        }
    }
}
