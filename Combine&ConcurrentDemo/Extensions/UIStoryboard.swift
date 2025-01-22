//
//  UIStoryboard.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import UIKit.UIStoryboard

extension UIStoryboard {
    static let main = UIStoryboard(name: "Main", bundle: .main)
}

extension UIStoryboard {
    func instantiate<T: StoryboardIdentifiable>(withClass: T.Type? = nil) -> T {
        guard let controller = instantiateViewController(withIdentifier: T.storyboardIdentifier) as? T else {
            fatalError("Controller with the identifier: \(T.storyboardIdentifier) not found")
        }
        return controller
    }
}


