//
//  AlertManager.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 27.03.2023.
//

import UIKit
import Combine
import CombineCocoa

final class AlertManager {
    
    // MARK: - AlertAction
    
    struct AlertAction {
        static let ok = AlertAction(title: "OK")
        static let cancel = AlertAction(title: "Cancel", style: .cancel)
        
        static let yes = AlertAction(title: "Yes")
        static let no = AlertAction(title: "No", style: .cancel)
        
        let title: String?
        let style: UIAlertAction.Style
        init(title: String?, style: UIAlertAction.Style = .default) {
            self.title = title
            self.style = style
        }
    }
    
    // MARK: - Methods
    
    @discardableResult static func showAlertOnTopVC<T: UIViewController>(of type: T.Type,
                                                      title: String? = nil,
                                                      message: String? = nil,
                                                      style: UIAlertController.Style = .alert,
                                                      actions: [AlertAction] = [.ok]) -> AnyPublisher<AlertAction, Never>? {
        let topViewController = UIViewController.topViewController
        guard topViewController is T else { return nil }
        return showAlert(on: topViewController, title: title, message: message, style: style, actions: actions)
    }
    
    @discardableResult static func showAlert(on viewController: UIViewController? = .topViewController,
                          title: String? = nil,
                          message: String? = nil,
                          style: UIAlertController.Style = .alert,
                          actions: [AlertAction] = [.ok]) -> AnyPublisher<AlertAction, Never> {
        return Future { promise in
            DispatchQueue.main.async {
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
     
                actions.forEach { action in
                    let handler: SimpleClosure<UIAlertAction>? = { _ in
                        promise(.success(action))
                        alertController.dismiss(animated: true)
                    }
                    alertController.addAction(.init(title: action.title, style: action.style, handler: handler))
                }
                
                viewController?.present(alertController, animated: true)
            }
        }.eraseToAnyPublisher()
    }
}
