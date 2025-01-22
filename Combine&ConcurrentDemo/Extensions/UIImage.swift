//
//  UIImage.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 29.03.2023.
//

import UIKit.UIImage

extension UIImage {
    convenience init?(from path: Path) {
        guard let data = try? Data(contentsOf: path) else { return nil }
        self.init(data: data)
    }
}
