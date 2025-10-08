//
//  TimeAmount+.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation

extension Duration {
    /// Converts Duration to TimeInterval (seconds)
    public var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds) + (TimeInterval(attoseconds) / 1_000_000_000_000_000_000)
    }

    /// Creates a new Duration from TimeInterval (seconds)
    public static func fromTimeInterval(_ timeInterval: TimeInterval) -> Duration {
        let seconds = Int64(timeInterval)
        let fractionalSeconds = timeInterval - TimeInterval(seconds)
        let attoseconds = Int64(fractionalSeconds * 1_000_000_000_000_000_000)
        return Duration(secondsComponent: seconds, attosecondsComponent: attoseconds)
    }

    /// Returns the maximum between self and other Duration
    public func max(_ other: Duration) -> Duration {
        return self > other ? self : other
    }

    /// Returns the minimum between self and other Duration
    public func min(_ other: Duration) -> Duration {
        return self < other ? self : other
    }

    /// Clamps the Duration between a minimum and maximum value
    public func clamped(to limits: ClosedRange<Duration>) -> Duration {
        if self < limits.lowerBound {
            return limits.lowerBound
        }
        if self > limits.upperBound {
            return limits.upperBound
        }
        return self
    }

    /// Total nanoseconds in the duration
    public var nanoseconds: Int64 {
        let (seconds, attoseconds) = self.components
        return (seconds * 1_000_000_000) + (attoseconds / 1_000_000_000)
    }

    /// Creates a Duration from a string representation
    /// Format: "123ms", "45s", "30m", "24h"
    public static func parse(_ string: String) throws -> Duration {
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
            return .seconds(value * 60)
        case "h":
            return .seconds(value * 3600)
        default:
            throw FirestoreError.invalidConfiguration("Invalid time unit: \(unit)")
        }
    }
}

extension Optional where Wrapped == Duration {
    public var timeInterval: TimeInterval? {
        return self?.timeInterval
    }
}
