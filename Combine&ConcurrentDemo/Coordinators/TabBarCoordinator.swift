//
//  TabBarCoordinator.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import UIKit

// MARK: - Protocols

protocol TabBarCoordinatorTransitions: AnyObject {}

protocol TabBarCoordinatorType: AnyObject {}

protocol TabBarCoordinatable {
    var rootVC: UIViewController { get }
}

class TabBarCoordinator {
    
    // MARK: - Properties
    
    private weak var window: UIWindow!
    private weak var tabBarController: UITabBarController!
    
    private lazy var coordinators: [TabBarCoordinatable] = {
        [
            MainCoordinator(transitions: self),
            HistoryCoordinator(transitions: self)
        ]
    }()
    
    private weak var transitions: TabBarCoordinatorTransitions?
    
    // MARK: - Init/Deinit
    
    init(window: UIWindow, transitions: TabBarCoordinatorTransitions?) {
        self.window = window
        self.transitions = transitions
        DebugPrinter.printInit(for: self)
    }
    
    deinit {
        DebugPrinter.printDeinit(for: self)
    }
    
    // MARK: - Methods
    
    func start() {
        let tabBarController = UITabBarController()
        self.tabBarController = tabBarController
        tabBarController.viewControllers = coordinators.map { $0.rootVC }
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}

// MARK: - TabBarCoordinatorType

extension TabBarCoordinator: TabBarCoordinatorType {}

// MARK: - MainCoordinatorTransitions

extension TabBarCoordinator: MainCoordinatorTransitions {}

// MARK: - HistoryCoordinatorTransitions

extension TabBarCoordinator: HistoryCoordinatorTransitions {}
