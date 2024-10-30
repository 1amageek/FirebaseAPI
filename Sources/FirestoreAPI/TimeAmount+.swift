//
//  TimeAmount+.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation
import NIO

extension TimeAmount {
    /// Converts TimeAmount to TimeInterval (seconds)
    public var timeInterval: TimeInterval {
        return TimeInterval(self.nanoseconds) / TimeInterval(1_000_000_000)
    }
    
    /// Creates a new TimeAmount from TimeInterval (seconds)
    public static func fromTimeInterval(_ timeInterval: TimeInterval) -> TimeAmount {
        let nanoseconds = Int64(timeInterval * TimeInterval(1_000_000_000))
        return .nanoseconds(nanoseconds)
    }
    
    /// Returns the maximum between self and other TimeAmount
    public func max(_ other: TimeAmount) -> TimeAmount {
        return self.nanoseconds > other.nanoseconds ? self : other
    }
    
    /// Returns the minimum between self and other TimeAmount
    public func min(_ other: TimeAmount) -> TimeAmount {
        return self.nanoseconds < other.nanoseconds ? self : other
    }
    
    /// Clamps the TimeAmount between a minimum and maximum value
    public func clamped(to limits: ClosedRange<TimeAmount>) -> TimeAmount {
        if self < limits.lowerBound {
            return limits.lowerBound
        }
        if self > limits.upperBound {
            return limits.upperBound
        }
        return self
    }
    
    /// Creates a TimeAmount from a string representation
    /// Format: "123ms", "45s", "30m", "24h"
    public static func parse(_ string: String) throws -> TimeAmount {
        let pattern = #"^(\d+)(ns|us|ms|s|m|h)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            throw FirestoreError.invalidConfiguration("Invalid time format: \(string)")
        }
        
        let valueRange = Range(match.range(at: 1), in: string)!
        let unitRange = Range(match.range(at: 2), in: string)!
        
        guard let value = Int64(string[valueRange]) else {
            throw FirestoreError.invalidConfiguration("Invalid time value: \(string[valueRange])")
        }
        
        let unit = String(string[unitRange])
        switch unit {
        case "ns":
            return .nanoseconds(value)
        case "us":
            return .microseconds(value)
        case "ms":
            return .milliseconds(value)
        case "s":
            return .seconds(value)
        case "m":
            return .minutes(value)
        case "h":
            return .hours(value)
        default:
            throw FirestoreError.invalidConfiguration("Invalid time unit: \(unit)")
        }
    }
}

extension Optional where Wrapped == TimeAmount {
    public var timeInterval: TimeInterval? {
        return self?.timeInterval
    }
}
