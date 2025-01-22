//
//  HistoryCoordinator.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import UIKit

// MARK: - Protocols

protocol HistoryCoordinatorTransitions: AnyObject {}

protocol HistoryCoordinatorType: AnyObject {
    func showImagesGreed(with images: [URL])
}

class HistoryCoordinator: TabBarCoordinatable {
    
    // MARK: - Properties
    
    private weak var navigationController: UINavigationController!
    private weak var transitions: HistoryCoordinatorTransitions?
    
    // MARK: - TabBarCoordinatable
    
    lazy var rootVC: UIViewController = {
        let historyVC = HistoryTVC(style: .plain)
        historyVC.viewModel = HistoryVM(coordiantor: self)
        
        let navigationController = UINavigationController(rootViewController: historyVC)
        navigationController.tabBarItem = .init(tabBarSystemItem: .history, tag: 0)
        self.navigationController = navigationController
        return navigationController
    }()
    
    // MARK: - Init/Deinit
    
    init(transitions: HistoryCoordinatorTransitions?) {
        self.transitions = transitions
        DebugPrinter.printInit(for: self)
    }
    
    deinit {
        DebugPrinter.printDeinit(for: self)
    }
}

// MARK: - ProfileTabCoordinatorType -

extension HistoryCoordinator: HistoryCoordinatorType {
    func showImagesGreed(with images: [URL]) {
        let photosGreedVC = ImagesGreedVC()
        photosGreedVC.images = images
        photosGreedVC.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(photosGreedVC, animated: true)
    }
}

