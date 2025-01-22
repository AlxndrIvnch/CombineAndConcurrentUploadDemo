//
//  DebugPrinter.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation
import UIKit

class DebugPrinter {
    static func printInit(for any: Any) {
        debugPrint("\(any) - init")
    }
    
    static func printDeinit(for any: Any) {
        debugPrint("\(any) - deinit")
    }
    
    static func printAppear(for any: UIViewController) {
        debugPrint("\(any) - appear")
    }
    
    static func printDisappear(for any: UIViewController) {
        debugPrint("\(any) - disappear")
    }
}
