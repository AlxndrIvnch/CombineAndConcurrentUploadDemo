//
//  String.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 26.03.2023.
//

import Foundation

//MARK: - Capitalized sentence
extension String {
    var capitalizedSentence: String {
        self.prefix(1).capitalized + self.dropFirst()
    }
}
