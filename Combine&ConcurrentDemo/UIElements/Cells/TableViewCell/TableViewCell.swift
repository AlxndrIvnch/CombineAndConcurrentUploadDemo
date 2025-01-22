//
//  TableViewCell.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    // MARK: - Properties

    var viewModel: TableViewCellVM!
    
    // MARK: - Setup
    
    func setup(with viewModel: TableViewCellVM) {
        var contentConfiguration = self.defaultContentConfiguration()
        contentConfiguration.text = viewModel.title
        contentConfiguration.secondaryText = viewModel.subtitle
        contentConfiguration.secondaryTextProperties.font = .systemFont(ofSize: 14)
        contentConfiguration.textToSecondaryTextVerticalPadding = 8
        contentConfiguration.prefersSideBySideTextAndSecondaryText = false
        contentConfiguration.image = viewModel.image
        self.contentConfiguration = contentConfiguration
    }

}
