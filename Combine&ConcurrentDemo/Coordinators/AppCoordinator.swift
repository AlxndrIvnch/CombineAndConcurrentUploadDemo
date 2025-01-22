//
//  AppCoordinator.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import UIKit

class AppCoordinator {
    
    // MARK: - Properties
    
    private var tabBarCoordinator: TabBarCoordinator?
    private weak var window: UIWindow!
    
    // MARK: - Init/Deinit
    
    init(window: UIWindow) {
        self.window = window
        DebugPrinter.printInit(for: self)
    }
    
    deinit {
        DebugPrinter.printDeinit(for: self)
    }
    
    //MARK: - Methods
    
    func start() {
        startTabBarCoordinator()
    }
    
    private func startTabBarCoordinator() {
        tabBarCoordinator = TabBarCoordinator(window: window, transitions: self)
        tabBarCoordinator?.start()
    }
}

//MARK: - TabBarCoordinatorTransitions

extension AppCoordinator: TabBarCoordinatorTransitions {}
