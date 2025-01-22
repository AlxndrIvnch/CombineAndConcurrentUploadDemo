//
//  Time.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

extension TimeInterval {
    var time: Time { Time(seconds: self) }
}

struct Time {
    
    // MARK: - Properties
    
    let years: Int
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    let milliseconds: Int
    
    var formatedString: String {
        var format = ""
        if years.isPositive {
            format += "%01dy "
        }
        if days.isPositive {
            format += "%02dd "
        }
        if hours.isPositive {
            format += "%01dh "
        }
        
        format += "%02d:%02d.%03d"
        return String(format: format, minutes, seconds, milliseconds)
    }
    
    // MARK: - Init
    
    init(seconds: TimeInterval) {
        let secondsInyear = 60 * 60 * 24 * 365
        let years = Int((seconds / Double(secondsInyear)).round(to: 4))
        let yearsInSeconds = Double(years * secondsInyear)
        
        let secondsInDay = 60 * 60 * 24
        let days = Int(((seconds - yearsInSeconds) / Double(secondsInDay)).round(to: 4))
        let daysInSeconds = Double(days * secondsInDay)
        
        let secondsInHour = 60 * 60
        let hours = Int(((seconds - daysInSeconds - yearsInSeconds) / Double(secondsInHour)).round(to: 4))
        let hoursInSeconds = Double(hours * secondsInHour)
        
        let secondsInMinute = 60
        let minutes = Int(((seconds - hoursInSeconds - daysInSeconds - yearsInSeconds) / Double(secondsInMinute)).round(to: 4))
        let minutesInSeconds = Double(minutes * secondsInMinute)
        
        let pureSeconds = Int(((seconds - minutesInSeconds - hoursInSeconds - daysInSeconds - yearsInSeconds)).round(to: 4))
        
        let secondsInMillisecond = 1.0 / 1000.0
        let milliseconds = Int(((seconds - Double(pureSeconds) - minutesInSeconds - hoursInSeconds - daysInSeconds - yearsInSeconds) / secondsInMillisecond).round(to: 4))
        
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = pureSeconds
        self.milliseconds = milliseconds
        self.years = years
    }
}
