//
//  UIProgressView.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 11.03.2023.
//

import UIKit.UIProgressView
import Combine

extension UIProgressView: Subscriber {
    public typealias Input = Progress
    public typealias Failure = Never
    
    public func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }
    
    public func receive(_ input: Progress) -> Subscribers.Demand {
        self.observedProgress = input
        return .unlimited
    }
    
    public func receive(completion: Subscribers.Completion<Never>) {}
}
